//
//  YTThumbsUpShape.swift
//  YiTechUI
//
//  Created by Sooyo on 2026-11-20.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.

import SwiftUI

/// Draws the thumbs-up icon path
struct YTThumbsUpShape: Shape {
    func path(in rect: CGRect) -> Path {
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: x, y: y)
        }

        var path = Path()
        path.move(to: point(815.588007, 438.766843))
        path.addCurve(
            to: point(774.411287, 417.320635),
            control1: point(805.582124, 426.032969),
            control2: point(790.581030, 418.219899)
        )
        path.addLine(to: point(629.073721, 417.320635))
        path.addCurve(
            to: point(600.855026, 410.683598),
            control1: point(614.490299, 417.320635),
            control2: point(603.880070, 414.792240)
        )
        path.addCurve(
            to: point(605.505467, 364.991887),
            control1: point(599.274779, 408.471252),
            control2: point(594.759788, 398.628572)
        )
        path.addCurve(
            to: point(591.192945, 210.804938),
            control1: point(619.908289, 319.480776),
            control2: point(619.772839, 249.949912)
        )
        path.addCurve(
            to: point(536.019753, 181.773545),
            control1: point(577.286772, 191.841975),
            control2: point(558.278659, 181.773545)
        )
        path.addCurve(
            to: point(448.248325, 241.552028),
            control1: point(477.008818, 181.773545),
            control2: point(453.079365, 219.383422)
        )
        path.addCurve(
            to: point(361.470194, 417.320635),
            control1: point(428.608113, 408.155203),
            control2: point(360.522046, 417.320635)
        )
        path.addLine(to: point(218.525573, 417.320635))
        path.addCurve(
            to: point(195.950617, 439.895591),
            control1: point(206.057769, 417.320635),
            control2: point(195.950617, 427.427787)
        )
        path.addLine(to: point(195.950617, 819.516049))
        path.addCurve(
            to: point(202.562669, 835.478953),
            control1: point(195.950617, 825.503300),
            control2: point(198.329043, 831.245328)
        )
        path.addCurve(
            to: point(218.525573, 842.091005),
            control1: point(206.796294, 839.712579),
            control2: point(212.538322, 842.091005)
        )
        path.addLine(to: point(667.225397, 842.091005))
        path.addCurve(
            to: point(758.428219, 796.308995),
            control1: point(749.804586, 842.091005),
            control2: point(758.067020, 801.636684)
        )
        path.addCurve(
            to: point(824.753439, 507.168959),
            control1: point(758.428219, 796.308995),
            control2: point(810.621517, 567.805291)
        )
        path.addCurve(
            to: point(815.588007, 438.766843),
            control1: point(831.345326, 478.363315),
            control2: point(828.320282, 455.336860)
        )

        path.closeSubpath()
        path.move(to: point(339.843915, 417.320635))
        path.addLine(to: point(339.843915, 842.091005))

        let bounds = path.boundingRect
        let scale = min(rect.width / bounds.width, rect.height / bounds.height) * 0.90
        let transform = CGAffineTransform(
            a: scale,
            b: 0,
            c: 0,
            d: scale,
            tx: rect.midX - bounds.midX * scale,
            ty: rect.midY - bounds.midY * scale
        )

        return path.applying(transform)
    }
}
