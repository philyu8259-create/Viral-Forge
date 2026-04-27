import { db, nowISO, parseJSON } from "../db/database.mjs";

const defaultBrandProfile = {
  brandName: "",
  industry: "",
  audience: "",
  tone: "",
  bannedWords: "",
  defaultPlatform: "xiaohongshu",
  primaryColorName: "Emerald"
};

export function getBrandProfile(userId) {
  const row = db.prepare(`
    SELECT profile_json
    FROM brand_profiles
    WHERE user_id = ?
  `).get(userId);

  if (!row) {
    return { ...defaultBrandProfile };
  }

  return {
    ...defaultBrandProfile,
    ...parseJSON(row.profile_json, {})
  };
}

export function saveBrandProfile(userId, profile) {
  const normalizedProfile = {
    ...defaultBrandProfile,
    ...profile
  };

  db.prepare(`
    INSERT INTO brand_profiles (
      user_id,
      profile_json,
      updated_at
    ) VALUES (?, ?, ?)
    ON CONFLICT(user_id) DO UPDATE SET
      profile_json = excluded.profile_json,
      updated_at = excluded.updated_at
  `).run(userId, JSON.stringify(normalizedProfile), nowISO());

  return normalizedProfile;
}
