import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:nexioza/core/database/app_database.dart';
import 'package:nexioza/core/models/organization.dart';
import 'package:nexioza/core/models/profile.dart';
import 'package:nexioza/core/models/project.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SyncService {
  SyncService(this._db, this._client);
  final AppDatabase _db;
  final SupabaseClient _client;

  Future<void> syncAll() async {
    await syncProfiles();
    await syncOrganizations();
    await syncProjects();
    await pushPendingMutations();
  }

  Future<void> syncProfiles() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return;

    final profile = Profile.fromJson(data);
    await _db
        .into(_db.localProfiles)
        .insert(
          LocalProfilesCompanion.insert(
            id: profile.id,
            displayName: Value(profile.displayName),
            avatarUrl: Value(profile.avatarUrl),
            version: Value(profile.version),
            createdAt: profile.createdAt,
            updatedAt: profile.updatedAt,
            syncStatus: const Value('synced'),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<void> syncOrganizations() async {
    final data = await _client
        .from('organizations')
        .select('*, organization_members(user_id, role)')
        .order('created_at');
    final orgs = data.map((e) => Organization.fromJson(e)).toList();

    await _db.batch((batch) {
      for (final org in orgs) {
        batch.insert(
          _db.localOrganizations,
          LocalOrganizationsCompanion.insert(
            id: org.id,
            name: org.name,
            ownerId: org.ownerId,
            version: Value(org.version),
            createdAt: org.createdAt,
            updatedAt: org.updatedAt,
            syncStatus: const Value('synced'),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> syncProjects() async {
    final data = await _client
        .from('projects')
        .select('*, project_members(user_id, role), organizations(name)')
        .eq('is_template', false)
        .order('created_at', ascending: false);
    final projects = data.map((e) => Project.fromJson(e)).toList();

    await _db.batch((batch) {
      for (final p in projects) {
        batch.insert(
          _db.localProjects,
          LocalProjectsCompanion.insert(
            id: p.id,
            organizationId: p.organizationId,
            name: p.name,
            description: Value(p.description),
            categoryId: Value(p.categoryId),
            icon: Value(p.icon),
            color: Value(p.color),
            isTemplate: Value(p.isTemplate),
            templateId: Value(p.templateId),
            metadata: Value(p.metadata != null ? jsonEncode(p.metadata) : null),
            version: Value(p.version),
            createdAt: p.createdAt,
            updatedAt: p.updatedAt,
            syncStatus: const Value('synced'),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> pushPendingMutations() async {
    final pending =
        await (_db.select(_db.pendingMutations)
              ..where((t) => t.status.equals('pending'))
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
            .get();

    for (final mutation in pending) {
      try {
        final payload = jsonDecode(mutation.payload) as Map<String, dynamic>;
        await _client.rpc<void>(mutation.operationType, params: payload);

        await (_db.update(_db.pendingMutations)
              ..where((t) => t.id.equals(mutation.id)))
            .write(const PendingMutationsCompanion(status: Value('completed')));
      } catch (e) {
        await (_db.update(
          _db.pendingMutations,
        )..where((t) => t.id.equals(mutation.id))).write(
          PendingMutationsCompanion(
            retryCount: Value(mutation.retryCount + 1),
            status: Value(mutation.retryCount >= 2 ? 'failed' : 'pending'),
          ),
        );
      }
    }
  }

  Future<void> queueMutation({
    required String operationType,
    required String entityType,
    String? entityId,
    required Map<String, dynamic> payload,
    required String idempotencyKey,
  }) async {
    await _db
        .into(_db.pendingMutations)
        .insert(
          PendingMutationsCompanion.insert(
            operationType: operationType,
            entityType: entityType,
            entityId: Value(entityId),
            payload: jsonEncode(payload),
            idempotencyKey: idempotencyKey,
            createdAt: DateTime.now(),
          ),
        );
  }

  Future<bool> hasConflict(
    String entityType,
    String entityId,
    int localVersion,
  ) async {
    switch (entityType) {
      case 'organization':
        final remote = await _client
            .from('organizations')
            .select('version')
            .eq('id', entityId)
            .maybeSingle();
        return remote != null && (remote['version'] as int) > localVersion;
      case 'project':
        final remote = await _client
            .from('projects')
            .select('version')
            .eq('id', entityId)
            .maybeSingle();
        return remote != null && (remote['version'] as int) > localVersion;
      default:
        return false;
    }
  }
}
