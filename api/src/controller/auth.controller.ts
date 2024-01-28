import { Request, Response } from "express";
import * as bcrypt from "bcrypt";
import * as jwt from "jsonwebtoken";
import * as nanoid from "nanoid";
import User from "../models/user.model";
import Token from "../models/token.model";
import { Env } from "../config/env-loader";

class AuthController {
	async Register(req: Request, res: Response): Promise<void> { 
		try {
			const { name, email, password, confirmPassword } = req.body;
			if (!name || !email || !password || !confirmPassword) {
				res.status(400).json({
					success: true,
					error: "Please provide all required fields" 
				});
			}

			const existUser = await User.findOne({
				where: { email } 
			});
			if (existUser) {
				res.status(400).json({
					success: false, 
					message: `User with ${email} already exist` 
				});
			}
			if (!email.includes("@")) {
				res.status(400).json({
					success: false,
					message: "Email format is invalid!"
				});
			}
			if (password.length < 8) {
				res.status(400).json({
					success: false,
					message: "Password must be at least 8 characters!"
				});
			}
			if (password !== confirmPassword) {
				res.status(403).json({
					success: false,
					message: "Password and confirm password don't match!"
				});
			}

			const salt = await bcrypt.genSalt();
			const hashedPassword = await bcrypt.hash(password, salt);

			const id = nanoid.nanoid(10);
			const uid = "fin-" + id;

			await User.create({
				uid: uid,
				name: name,
				email: email,
				password: hashedPassword,
			});
			res.status(201).json({
				success: true,
				message: "User registered successfully",
				data: {
					name,
					email
				}
			});
			
		} catch (error) {
			console.error(error);
			res.status(500).json({
				success: false,
				message: "Internal server error"
			});
		}
	}

	async Login(req: Request, res: Response): Promise<void> {
		try {
			const { email, password } = req.body;

			const user = await User.findOne({ 
				where: { email },
			});
			
			if (!user) {
				res.status(401).json({
					success: false,
					message: "User not registered"
				});
				return;
			}

			const uid = user.uid;
			const name = user.name;

			const isMatch = await bcrypt.compare(password, user.password);
			if (!isMatch) {
				res.status(401).json({
					success: false,
					message: "Invalid password"
				});
			}

			const token = jwt.sign({ uid, name }, Env.JWT_SECRET, {
				expiresIn: "24h"
			});

			const refreshToken = jwt.sign({ uid, name }, Env.JWT_SECRET, {
				expiresIn: "7d"
			});

			await Token.create({
				uid: uid,
				token: refreshToken,
			});
			
			res.cookie("token", token, {
				httpOnly: true,
				sameSite: true,
				maxAge: 24 * 60 * 60 * 1000,
				secure: false
			});

			res.status(200).json({
				success: true,
				message: "Login successful",
				data: {
					uid,
					name,
					email,
				}
			});
		} catch (error) {
			console.error(error);
			res.status(500).json({
				success: false,
				message: "Internal server error"
			});
		}
	}

	async Logout(req: Request, res: Response): Promise<void> { 
		try {
			const token = req.cookies.token;

			if (!token) {
				res.status(204);
			}

			const decoded = jwt.decode(token);

			if (typeof decoded === "object" && decoded !== null && "uid" in decoded) {
				req.uid = decoded.uid;
			}

			const user = await User.findOne({
				where: {
					uid: req.uid
				}
			});

			if (!user) {
				res.status(401).json({
					success: false,
					message: "User not found"
				});
			}

			await Token.destroy({
				where: {
					uid: req.uid
				}
			});

			res.clearCookie("token");

			res.status(200).json({
				success: true,
				message: "Logout successful"
			});

		} catch (error) {
			console.log(error);
			res.status(500).json({
				success: false,
				message: "Internal server error"
			});
		}
	}

}

export default new AuthController();