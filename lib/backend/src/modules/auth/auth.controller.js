import * as service from './auth.service.js';
import { ok } from '../../utils/response.js';
import { registerSchema, loginSchema, refreshSchema } from './auth.schema.js';

export async function register(req, res) {
  const input = registerSchema.parse(req.body);
  ok(res, await service.register(input), 'Registrasi berhasil', 201);
}

export async function login(req, res) {
  const input = loginSchema.parse(req.body);
  ok(res, await service.login(input), 'Login berhasil');
}

export async function refresh(req, res) {
  const { refreshToken } = refreshSchema.parse(req.body);
  ok(res, await service.refresh(refreshToken), 'Token diperbarui');
}

export async function logout(req, res) {
  const { refreshToken } = refreshSchema.parse(req.body);
  await service.logout(refreshToken);
  ok(res, null, 'Logout berhasil');
}

export async function me(req, res) {
  ok(res, await service.getMe(req.user.id));
}