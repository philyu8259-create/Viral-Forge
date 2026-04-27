import { randomUUID } from "node:crypto";
import { db, nowISO, parseJSON } from "../db/database.mjs";

export function saveProject(userId, project) {
  const projectId = project.projectId ?? project.result?.projectId ?? randomUUID();
  const createdAt = project.createdAt ?? nowISO();
  const updatedAt = project.updatedAt ?? nowISO();
  const normalizedProject = {
    ...project,
    projectId,
    createdAt,
    updatedAt
  };

  db.prepare(`
    INSERT INTO projects (
      user_id,
      project_id,
      created_at,
      updated_at,
      input_json,
      result_json,
      payload_json
    ) VALUES (?, ?, ?, ?, ?, ?, ?)
    ON CONFLICT(user_id, project_id) DO UPDATE SET
      updated_at = excluded.updated_at,
      input_json = excluded.input_json,
      result_json = excluded.result_json,
      payload_json = excluded.payload_json
  `).run(
    userId,
    projectId,
    createdAt,
    updatedAt,
    JSON.stringify(normalizedProject.input ?? {}),
    JSON.stringify(normalizedProject.result ?? {}),
    JSON.stringify(normalizedProject)
  );

  return normalizedProject;
}

export function listProjects(userId) {
  return db.prepare(`
    SELECT payload_json
    FROM projects
    WHERE user_id = ?
    ORDER BY created_at DESC
  `)
    .all(userId)
    .map((row) => parseJSON(row.payload_json, {}));
}

export function deleteProject(userId, projectId) {
  const result = db.prepare(`
    DELETE FROM projects
    WHERE user_id = ? AND project_id = ?
  `).run(userId, projectId);
  return result.changes > 0;
}

export function resetStore() {
    db.exec("DELETE FROM projects;");
}
