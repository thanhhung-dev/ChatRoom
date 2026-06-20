//
//  Theme.swift
//  BoxChat
//
//  Centralized design system for BoxChat.
//  All UI constants (colors, typography, spacing, shadows, animations)
//  should be referenced from BCTheme to ensure visual consistency.
//

import UIKit

// MARK: - BCTheme

enum BCTheme {

    // MARK: - Colors

    enum Colors {

        // MARK: Brand

        /// Primary brand blue — buttons, links, active states, tab bar tint
        static let primary = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.35, green: 0.62, blue: 1.00, alpha: 1.0)   // #5A9FFF
                : UIColor(red: 0.20, green: 0.47, blue: 0.96, alpha: 1.0)   // #3478F6
        }

        /// Soft primary — selected backgrounds, light highlight areas
        static let primarySoft = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.10, green: 0.17, blue: 0.29, alpha: 1.0)   // #1A2B4A
                : UIColor(red: 0.92, green: 0.95, blue: 1.00, alpha: 1.0)   // #EBF2FF
        }

        /// Accent purple — gradients, secondary emphasis, premium touches
        static let accent = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.61, green: 0.54, blue: 1.00, alpha: 1.0)   // #9B8AFF
                : UIColor(red: 0.48, green: 0.38, blue: 1.00, alpha: 1.0)   // #7B61FF
        }

        // MARK: Text

        static let textPrimary   = UIColor.label
        static let textSecondary = UIColor.secondaryLabel
        static let textTertiary  = UIColor.tertiaryLabel
        static let textOnPrimary = UIColor.white

        // MARK: Surfaces

        static let background        = UIColor.systemBackground
        static let backgroundGrouped = UIColor.systemGroupedBackground
        static let surface           = UIColor.secondarySystemBackground
        static let surfaceElevated   = UIColor.tertiarySystemBackground

        // MARK: Chat Bubbles

        static let bubbleOutgoing = UIColor { _ in
            UIColor(red: 0.20, green: 0.47, blue: 0.96, alpha: 1.0)         // #3478F6
        }

        static let bubbleIncoming = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.15, green: 0.15, blue: 0.19, alpha: 1.0)   // #262630
                : UIColor(red: 0.91, green: 0.92, blue: 0.95, alpha: 1.0)   // #E8EBF2
        }

        static let bubbleTextOutgoing: UIColor = .white
        static let bubbleTextIncoming: UIColor = .label

        // MARK: Status

        static let success     = UIColor(red: 0.19, green: 0.82, blue: 0.35, alpha: 1.0) // #30D158
        static let destructive = UIColor.systemRed
        static let error       = destructive
        static let warning     = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 1.00, green: 0.84, blue: 0.04, alpha: 1.0)   // #FFD60A
                : UIColor(red: 1.00, green: 0.72, blue: 0.00, alpha: 1.0)   // #FFB800
        }
        static let online = success

        // MARK: Separators

        static let separator      = UIColor.separator
        static let separatorLight = UIColor.separator.withAlphaComponent(0.12)

        // MARK: Avatar Palette

        /// Hash-stable color palette for initials-based avatars
        static let avatarPalette: [UIColor] = [
            UIColor(red: 0.36, green: 0.42, blue: 0.94, alpha: 1.0), // Indigo
            UIColor(red: 1.00, green: 0.42, blue: 0.54, alpha: 1.0), // Coral
            UIColor(red: 0.18, green: 0.83, blue: 0.75, alpha: 1.0), // Teal
            UIColor(red: 1.00, green: 0.71, blue: 0.28, alpha: 1.0), // Amber
            UIColor(red: 0.65, green: 0.55, blue: 0.98, alpha: 1.0), // Lavender
            UIColor(red: 0.96, green: 0.45, blue: 0.71, alpha: 1.0), // Pink
            UIColor(red: 0.20, green: 0.83, blue: 0.60, alpha: 1.0), // Emerald
            UIColor(red: 0.98, green: 0.57, blue: 0.24, alpha: 1.0), // Orange
        ]

        /// Deterministic avatar color based on a name string
        static func avatarColor(for name: String) -> UIColor {
            let hash = abs(name.hashValue)
            return avatarPalette[hash % avatarPalette.count]
        }

        // MARK: Ambient Orbs (Auth backgrounds)

        static let orbBlue = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.20, green: 0.47, blue: 0.96, alpha: 0.12)
                : UIColor(red: 0.20, green: 0.47, blue: 0.96, alpha: 0.15)
        }

        static let orbPurple = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.48, green: 0.38, blue: 1.00, alpha: 0.08)
                : UIColor(red: 0.48, green: 0.38, blue: 1.00, alpha: 0.10)
        }

        static let orbTeal = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.18, green: 0.83, blue: 0.75, alpha: 0.06)
                : UIColor(red: 0.18, green: 0.83, blue: 0.75, alpha: 0.10)
        }
    }

    // MARK: - Typography

    enum Typography {
        static let displayLarge = UIFont.systemFont(ofSize: 40, weight: .bold)
        static let displayMedium = UIFont.systemFont(ofSize: 34, weight: .bold)
        static let largeTitle   = UIFont.systemFont(ofSize: 32, weight: .heavy)
        static let title1       = UIFont.systemFont(ofSize: 28, weight: .bold)
        static let title2       = UIFont.systemFont(ofSize: 22, weight: .bold)
        static let title3       = UIFont.systemFont(ofSize: 20, weight: .semibold)
        static let title        = title2
        static let headline     = UIFont.systemFont(ofSize: 17, weight: .semibold)
        static let body         = UIFont.systemFont(ofSize: 15, weight: .regular)
        static let bodyBold     = UIFont.systemFont(ofSize: 15, weight: .semibold)
        static let callout      = UIFont.systemFont(ofSize: 14, weight: .medium)
        static let calloutBold  = UIFont.systemFont(ofSize: 14, weight: .bold)
        static let subheadline  = UIFont.systemFont(ofSize: 13, weight: .semibold)
        static let subheadlineBold = UIFont.systemFont(ofSize: 13, weight: .bold)
        static let caption      = UIFont.systemFont(ofSize: 12, weight: .medium)
        static let captionItalic = UIFont.italicSystemFont(ofSize: 12)
        static let captionBold  = UIFont.systemFont(ofSize: 12, weight: .semibold)
        static let micro        = UIFont.systemFont(ofSize: 10, weight: .medium)
        static let microBold    = UIFont.systemFont(ofSize: 10, weight: .bold)
    }

    // MARK: - Layout

    enum Layout {
        // Corner Radii
        static let radiusXS:   CGFloat = 8
        static let radiusS:    CGFloat = 12
        static let radiusM:    CGFloat = 16
        static let radiusL:    CGFloat = 22
        static let radiusXL:   CGFloat = 28
        static let radiusFull: CGFloat = 9999   // pills
        static let cornerRadiusXS = radiusXS
        static let cornerRadiusS  = radiusS
        static let cornerRadiusM  = radiusM
        static let cornerRadiusL  = radiusL
        static let cornerRadiusXL = radiusXL

        // Padding / Spacing
        static let paddingXS:  CGFloat = 4
        static let paddingS:   CGFloat = 8
        static let paddingM:   CGFloat = 16
        static let paddingL:   CGFloat = 24
        static let paddingXL:  CGFloat = 32
        static let paddingXXL: CGFloat = 40

        // Standard Heights
        static let buttonHeight: CGFloat = 52
        static let fieldHeight:  CGFloat = 50
        static let cellHeight:   CGFloat = 76

        // Avatar Sizes
        static let avatarXS: CGFloat = 28
        static let avatarS:  CGFloat = 36
        static let avatarM:  CGFloat = 50
        static let avatarL:  CGFloat = 88
        static let avatarXL: CGFloat = 120

        // Content
        static let maxBubbleWidthRatio: CGFloat = 0.74
        static let horizontalMargin:    CGFloat = 24
    }

    // MARK: - Shadows

    enum Shadow {
        static func apply(
            to view: UIView,
            color: UIColor = .label,
            opacity: Float = 0.08,
            radius: CGFloat = 12,
            offset: CGSize = CGSize(width: 0, height: 4)
        ) {
            view.layer.shadowColor   = color.cgColor
            view.layer.shadowOpacity = opacity
            view.layer.shadowRadius  = radius
            view.layer.shadowOffset  = offset
        }

        /// Subtle card shadow
        static func card(_ view: UIView) {
            apply(to: view, opacity: 0.06, radius: 16,
                  offset: CGSize(width: 0, height: 6))
        }

        /// Primary button glow
        static func button(_ view: UIView) {
            apply(to: view, color: Colors.primary, opacity: 0.25,
                  radius: 12, offset: CGSize(width: 0, height: 6))
        }

        /// Elevated element (modals, toasts)
        static func elevated(_ view: UIView) {
            apply(to: view, opacity: 0.12, radius: 24,
                  offset: CGSize(width: 0, height: 8))
        }

        /// Very subtle shadow for input fields
        static func subtle(_ view: UIView) {
            apply(to: view, opacity: 0.04, radius: 8,
                  offset: CGSize(width: 0, height: 2))
        }

        /// Call after trait changes to refresh CGColor-based shadow colors
        static func updateShadowColor(_ view: UIView, color: UIColor = .label) {
            view.layer.shadowColor = color.cgColor
        }
    }

    // MARK: - Animations

    enum Animation {
        static let springDamping:   CGFloat       = 0.72
        static let springVelocity:  CGFloat       = 0.5
        static let defaultDuration: TimeInterval  = 0.3
        static let quickDuration:   TimeInterval  = 0.15

        /// Tactile press-down (call on .touchDown)
        static func pressDown(_ view: UIView) {
            UIView.animate(withDuration: 0.1, delay: 0,
                           options: [.allowUserInteraction, .curveEaseIn]) {
                view.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
            }
        }

        /// Spring release (call on .touchUpInside / .touchUpOutside / .touchCancel)
        static func pressUp(_ view: UIView) {
            UIView.animate(withDuration: 0.4, delay: 0,
                           usingSpringWithDamping: 0.6,
                           initialSpringVelocity: 0.8,
                           options: [.allowUserInteraction]) {
                view.transform = .identity
            }
        }

        /// Staggered entrance — each view fades in + slides up
        static func staggerEntrance(_ views: [UIView], baseDelay: TimeInterval = 0.05) {
            for (i, v) in views.enumerated() {
                v.alpha = 0
                v.transform = CGAffineTransform(translationX: 0, y: 20)
                UIView.animate(withDuration: 0.5,
                               delay: baseDelay * Double(i),
                               usingSpringWithDamping: 0.78,
                               initialSpringVelocity: 0.3,
                               options: .curveEaseOut) {
                    v.alpha = 1
                    v.transform = .identity
                }
            }
        }

        /// Simple fade
        static func fade(_ view: UIView, to alpha: CGFloat,
                         duration: TimeInterval = defaultDuration) {
            UIView.animate(withDuration: duration, delay: 0,
                           options: .curveEaseInOut) {
                view.alpha = alpha
            }
        }

        /// Spring scale
        static func springScale(_ view: UIView, to scale: CGFloat = 1.0) {
            UIView.animate(withDuration: 0.5, delay: 0,
                           usingSpringWithDamping: springDamping,
                           initialSpringVelocity: springVelocity,
                           options: .curveEaseOut) {
                view.transform = scale == 1.0
                    ? .identity
                    : CGAffineTransform(scaleX: scale, y: scale)
            }
        }
    }
}

// MARK: - UIView + Convenience

extension UIView {
    /// Apply continuous (squircle) corner radius
    func bcCornerRadius(_ radius: CGFloat) {
        layer.cornerRadius = radius
        layer.cornerCurve  = .continuous
    }

    /// Apply standard card styling (surface bg + shadow + corner radius)
    func bcCardStyle(cornerRadius: CGFloat = BCTheme.Layout.radiusL) {
        bcCornerRadius(cornerRadius)
        backgroundColor = BCTheme.Colors.surface
        BCTheme.Shadow.card(self)
    }
}
