import type { NextFunction, Request, Response } from "express";
import { Prisma, type Profile } from "@prisma/client";
import {
  AuthInvalidJwtError,
  AuthUnknownError,
  isAuthApiError,
  isAuthError,
  isAuthRetryableFetchError,
  isAuthSessionMissingError,
} from "@supabase/supabase-js";
import { z } from "zod";
import { AppError } from "./errors";
import { prisma } from "./prisma";
import { supabase } from "./supabase";

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      profile?: Profile;
      userEmail?: string;
    }
  }
}

const invalidToken = () => new AppError(401, "INVALID_TOKEN", "Invalid or expired token");
const authUnavailable = () =>
  new AppError(503, "AUTH_UNAVAILABLE", "Could not verify the session, try again");

function resolveTimezone(header: string | undefined): string {
  if (!header) return "UTC";
  try {
    return new Intl.DateTimeFormat("en-US", { timeZone: header }).resolvedOptions().timeZone;
  } catch {
    return "UTC";
  }
}

/**
 * Maps a getClaims failure to 401 (the token is bad) or 503 (Supabase could not be reached).
 * Unknown cases fall back to 401, so a request is never let through by mistake.
 */
function toAuthAppError(error: unknown): AppError {
  // Network failure (status 0) or a 5xx/52x response, e.g. the JWKS fetch failed.
  if (isAuthRetryableFetchError(error)) return authUnavailable();
  // Supabase answered with a body that was not JSON.
  if (error instanceof AuthUnknownError) return authUnavailable();
  // Bad structure, bad base64, expired, or signature mismatch.
  if (error instanceof AuthInvalidJwtError) return invalidToken();
  // HS256 fallback (getUser): the session behind the token no longer exists.
  if (isAuthSessionMissingError(error)) return invalidToken();
  if (isAuthApiError(error)) {
    const status = error.status ?? 500;
    return status === 429 || status >= 500 ? authUnavailable() : invalidToken();
  }
  if (isAuthError(error)) return invalidToken();
  // getClaims rethrows non-auth errors, which only come from parsing or verifying
  // the token itself (JSON.parse of the payload, unsupported alg, WebCrypto).
  return invalidToken();
}

async function verifyToken(token: string): Promise<{ userId: string; email?: string }> {
  let result: Awaited<ReturnType<typeof supabase.auth.getClaims>>;
  try {
    result = await supabase.auth.getClaims(token);
  } catch (err) {
    throw toAuthAppError(err);
  }
  const { data, error } = result;
  if (error || !data) {
    throw toAuthAppError(error);
  }

  const { sub, email } = data.claims;
  // Profile ids are UUIDs; tokens without a user (e.g. service keys) are rejected.
  if (!z.uuid().safeParse(sub).success) {
    throw invalidToken();
  }
  return { userId: sub, email: typeof email === "string" && email !== "" ? email : undefined };
}

async function loadOrCreateProfile(id: string, timezoneHeader: string | undefined): Promise<Profile> {
  const existing = await prisma.profile.findUnique({ where: { id } });
  if (existing) return existing;

  // First request creates the profile row.
  try {
    return await prisma.profile.create({
      data: { id, timezone: resolveTimezone(timezoneHeader) },
    });
  } catch (err) {
    // Two first requests at once: the other one created the row.
    if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === "P2002") {
      const created = await prisma.profile.findUnique({ where: { id } });
      if (created) return created;
    }
    throw err;
  }
}

export async function requireAuth(req: Request, _res: Response, next: NextFunction) {
  const authHeader = req.header("authorization");
  const token = authHeader?.startsWith("Bearer ") ? authHeader.slice(7).trim() : undefined;
  if (!token) {
    throw new AppError(401, "UNAUTHORIZED", "Missing or malformed Authorization header");
  }

  const { userId, email } = await verifyToken(token);
  const profile = await loadOrCreateProfile(userId, req.header("x-timezone"));

  if (profile.deletedAt) {
    throw new AppError(403, "ACCOUNT_DELETED", "This account has been deleted");
  }
  if (profile.isDisabled) {
    throw new AppError(403, "ACCOUNT_DISABLED", "This account is disabled");
  }

  req.profile = profile;
  req.userEmail = email;
  next();
}
