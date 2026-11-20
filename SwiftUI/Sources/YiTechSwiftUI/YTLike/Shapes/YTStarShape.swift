//
//  YTStarShape.swift
//  YiTechUI
//
//  Created by Sooyo on 2026-11-20.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.

import SwiftUI

/// Draws the rounded star icon path
struct YTStarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) * 0.46
        let innerRadius = outerRadius * 0.42
        let vertices = (0..<10).map { point in
            let angle = CGFloat(point) * .pi / 5 - .pi / 2
            let radius = point.isMultiple(of: 2) ? outerRadius : innerRadius

            return CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )
        }

        func insetPoint(from vertex: CGPoint, toward neighbor: CGPoint, distance: CGFloat) -> CGPoint {
            let dx = neighbor.x - vertex.x
            let dy = neighbor.y - vertex.y
            let edgeLength = hypot(dx, dy)

            return CGPoint(
                x: vertex.x + dx / edgeLength * distance,
                y: vertex.y + dy / edgeLength * distance
            )
        }

        var path = Path()
        for index in vertices.indices {
            let vertex = vertices[index]
            let previous = vertices[(index + vertices.count - 1) % vertices.count]
            let next = vertices[(index + 1) % vertices.count]
            let cornerRatio = index.isMultiple(of: 2) ? 0.28 : 0.16

            let entry = insetPoint(
                from: vertex,
                toward: previous,
                distance: hypot(previous.x - vertex.x, previous.y - vertex.y) * cornerRatio
            )

            let exit = insetPoint(
                from: vertex,
                toward: next,
                distance: hypot(next.x - vertex.x, next.y - vertex.y) * cornerRatio
            )

            if index == 0 {
                path.move(to: entry)
            } else {
                path.addLine(to: entry)
            }

            path.addQuadCurve(to: exit, control: vertex)
        }

        path.closeSubpath()
        return path
    }
}
