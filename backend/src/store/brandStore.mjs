import { backend } from "./storageBackend.mjs";

const defaultBrandProfile = {
  brandName: "",
  industry: "",
  audience: "",
  tone: "",
  bannedWords: "",
  defaultPlatform: "xiaohongshu",
  primaryColorName: "Emerald"
};

export async function getBrandProfile(userId) {
  const store = await backend();
  const row = await store.getBrandRecord(userId);

  if (!row) {
    return { ...defaultBrandProfile };
  }

  return {
    ...defaultBrandProfile,
    ...store.parseJSON(row.profile_json, {})
  };
}

export async function saveBrandProfile(userId, profile) {
  const normalizedProfile = {
    ...defaultBrandProfile,
    ...profile
  };

  const store = await backend();
  await store.putBrandRecord(userId, normalizedProfile);

  return normalizedProfile;
}
