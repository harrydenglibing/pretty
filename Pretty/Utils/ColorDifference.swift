//
//  ColorDifference.swift
//  Pretty
//
//  Created by Octree on 2018/4/7.
//  Copyright © 2018年 Octree. All rights reserved.
//

import GLKit

extension GLKVector3 {
    
    func unpack() -> (Float, Float, Float) {
        
        return (x, y, z)
    }
}

private func C(_ a: Float, b: Float) -> Float {
    return sqrt(pow(a, 2) + pow(b, 2))
}

// From http://www.brucelindbloom.com/index.html?Eqn_DeltaE_CIE2000.html
public func CIE2000SquaredColorDifference(
    _ kL: Float = 1,
    kC: Float = 1,
    kH: Float = 1
    ) -> (_ lab1:GLKVector3, _ lab2:GLKVector3) -> Float {
    
    return { (lab1:GLKVector3, lab2:GLKVector3) -> Float in
        let (L1, a1, b1) = lab1.unpack()
        let (L2, a2, b2) = lab2.unpack()
        
        let ΔLp = L2 - L1
        let Lbp = (L1 + L2) / 2
        
        let (C1, C2) = (C(a1, b: b1), C(a2, b: b2))
        let Cb = (C1 + C2) / 2
        
        let G = (1 - sqrt(pow(Cb, 7) / (pow(Cb, 7) + pow(25, 7)))) / 2
        let ap: (Float) -> Float = { a in
            return a * (1 + G)
        }
        let (a1p, a2p) = (ap(a1), ap(a2))
        
        let (C1p, C2p) = (C(a1p, b: b1), C(a2p, b: b2))
        let ΔCp = C2p - C1p
        let Cbp = (C1p + C2p) / 2
        
        let hp: (Float, Float) -> Float = { ap, b in
            if ap == 0 && b == 0 { return 0 }
            let θ = GLKMathRadiansToDegrees(atan2(b, ap))
            return fmod(θ < 0 ? (θ + 360) : θ, 360)
        }
        let (h1p, h2p) = (hp(a1p, b1), hp(a2p, b2))
        let Δhabs = abs(h1p - h2p)
        let Δhp: Float = {
            if (C1p == 0 || C2p == 0) {
                return 0
            } else if Δhabs <= 180 {
                return h2p - h1p
            } else if h2p <= h1p {
                return h2p - h1p + 360
            } else {
                return h2p - h1p - 360
            }
        }()
        
        let ΔHp = 2 * sqrt(C1p * C2p) * sin(GLKMathDegreesToRadians(Δhp / 2))
        let Hbp: Float = {
            if (C1p == 0 || C2p == 0) {
                return h1p + h2p
            } else if Δhabs > 180 {
                return (h1p + h2p + 360) / 2
            } else {
                return (h1p + h2p) / 2
            }
        }()
        
        var T = 1
            - 0.17 * cos(GLKMathDegreesToRadians(Hbp - 30))
            + 0.24 * cos(GLKMathDegreesToRadians(2 * Hbp))
        
        T = T
            + 0.32 * cos(GLKMathDegreesToRadians(3 * Hbp + 6))
            - 0.20 * cos(GLKMathDegreesToRadians(4 * Hbp - 63))
        
        let Sl = 1 + (0.015 * pow(Lbp - 50, 2)) / sqrt(20 + pow(Lbp - 50, 2))
        let Sc = 1 + 0.045 * Cbp
        let Sh = 1 + 0.015 * Cbp * T
        
        let Δθ = 30 * exp(-pow((Hbp - 275) / 25, 2))
        let Rc = 2 * sqrt(pow(Cbp, 7) / (pow(Cbp, 7) + pow(25, 7)))
        let Rt = -Rc * sin(GLKMathDegreesToRadians(2 * Δθ))
        
        let Lterm = ΔLp / (kL * Sl)
        let Cterm = ΔCp / (kC * Sc)
        let Hterm = ΔHp / (kH * Sh)
        return pow(Lterm, 2) + pow(Cterm, 2) + pow(Hterm, 2) + Rt * Cterm * Hterm
    }
}
