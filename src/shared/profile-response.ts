import type { Profile } from "@prisma/client";

export type ProfileResponse = {
  id: string;
  email: string | null;
  name: string | null;
  birth_year: number | null;
  height_cm: number | null;
  target_weight_kg: number | null;
  units: Profile["units"];
  timezone: string;
  avatar_url: string | null;
  role: Profile["role"];
  plan: Profile["plan"];
  onboarding_completed: boolean;
  created_at: string;
};

export function toProfileResponse(profile: Profile, email: string | null | undefined): ProfileResponse {
  return {
    id: profile.id,
    email: email ?? null,
    name: profile.name,
    birth_year: profile.birthYear,
    height_cm: profile.heightCm?.toNumber() ?? null,
    target_weight_kg: profile.targetWeightKg?.toNumber() ?? null,
    units: profile.units,
    timezone: profile.timezone,
    avatar_url: profile.avatarUrl,
    role: profile.role,
    plan: profile.plan,
    onboarding_completed: profile.onboardingCompleted,
    created_at: profile.createdAt.toISOString(),
  };
}
