import { Router } from "express";
import { requireAuth } from "../shared/auth";
import { AppError } from "../shared/errors";
import { toProfileResponse } from "../shared/profile-response";

export const meRouter = Router();

meRouter.get("/me", requireAuth, (req, res) => {
  const profile = req.profile;
  if (!profile) {
    throw new AppError(401, "UNAUTHORIZED", "Not authenticated");
  }

  res.json(toProfileResponse(profile, req.userEmail));
});
