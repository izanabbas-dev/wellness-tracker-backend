import type { NextFunction, Request, Response } from "express";
import type { Profile } from "@prisma/client";
import { AppError } from "./errors";
import { prisma } from "./prisma";
import { supabase } from "./supabase";

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      profile?: Profile;
    }
  }
}

function resolveTimezone(header: string | undefined): string {
  if (!header) return "UTC";
  try {
    new Intl.DateTimeFormat("en-US", { timeZone: header });
    return header;
  } catch {
    return "UTC";
  }
}

export async function requireAuth(req: Request, _res: Response, next: NextFunction) {
  const authHeader = req.header("authorization");
  const token = authHeader?.startsWith("Bearer ") ? authHeader.slice(7).trim() : undefined;
  if (!token) {
    throw new AppError(401, "UNAUTHORIZED", "Missing or malformed Authorization header");
  }

  const { data, error } = await supabase.auth.getUser(token);
  if (error || !data.user) {
    throw new AppError(401, "INVALID_TOKEN", "Invalid or expired token");
  }

  // First request creates the profile row; later requests just read it.
  const profile = await prisma.profile.upsert({
    where: { id: data.user.id },
    update: {},
    create: {
      id: data.user.id,
      timezone: resolveTimezone(req.header("x-timezone")),
    },
  });

  if (profile.deletedAt) {
    throw new AppError(403, "ACCOUNT_DELETED", "This account has been deleted");
  }
  if (profile.isDisabled) {
    throw new AppError(403, "ACCOUNT_DISABLED", "This account is disabled");
  }

  req.profile = profile;
  next();
}