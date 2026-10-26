import { Router } from "express";
import { requireAuth } from "../shared/auth";
import { AppError } from "../shared/errors";

export const meRouter = Router();

meRouter.get("/me", requireAuth, (req, res) => {
  const profile = req.profile;
  if (!profile) {
    throw new AppError(401, "UNAUTHORIZED", "Not authenticated");
  }

  res.json({
    id: profile.id,
    name: profile.name,
    birthYear: profile.birthYear,
    heightCm: profile.heightCm?.toNumber() ?? null,
    targetWeightKg: profile.targetWeightKg?.toNumber() ?? null,
    units: profile.units,
    timezone: profile.timezone,
    avatarUrl: profile.avatarUrl,
    role: profile.role,
    plan: profile.plan,
    onboardingCompleted: profile.onboardingCompleted,
    createdAt: profile.createdAt,
  });
});
