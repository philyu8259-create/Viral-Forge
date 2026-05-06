import { randomUUID } from "node:crypto";
import { backend } from "./storageBackend.mjs";

export async function saveProject(userId, project) {
  const store = await backend();
  const projectId = project.projectId ?? project.result?.projectId ?? randomUUID();
  const createdAt = project.createdAt ?? store.nowISO();
  const updatedAt = project.updatedAt ?? store.nowISO();
  const normalizedProject = {
    ...project,
    projectId,
    createdAt,
    updatedAt
  };

  await store.saveProjectRecord(userId, normalizedProject);

  return normalizedProject;
}

export async function listProjects(userId) {
  const store = await backend();
  return store.listProjectRecords(userId);
}

export async function deleteProject(userId, projectId) {
  const store = await backend();
  return store.deleteProjectRecord(userId, projectId);
}

export async function resetStore() {
  const store = await backend();
  await store.resetProjectRecords();
}
