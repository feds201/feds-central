"use client";
"use client";
import { useState, useEffect } from "react";
import { useTheme } from "nextra-theme-docs";

export const Button = ({
  children,
  variant = "primary",
  size = "medium",
  icon,
  iconPosition = "left",
  disabled = false,
  loading = false,
  fullWidth = false,
  onClick,
  href,
  target,
  gradient,
  className = "",
  style = {},
  ...props
}) => {
  const { theme } = useTheme();
  const [mounted, setMounted] = useState(false);
  const [isHovered, setIsHovered] = useState(false);
  const [isPressed, setIsPressed] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) return null;

  const isDark = theme === "dark";

  // Size configurations
  const sizes = {
    small: {
      padding: "8px 16px",
      fontSize: "14px",
      height: "36px",
    },
    medium: {
      padding: "12px 24px",
      fontSize: "16px",
      height: "44px",
    },
    large: {
      padding: "16px 32px",
      fontSize: "18px",
      height: "52px",
    },
  };

  // Variant configurations
  const variants = {
    primary: {
      background:
        gradient || "linear-gradient(135deg, #667eea 0%, #764ba2 100%)",
      color: "white",
      border: "none",
      boxShadow: "0 8px 32px rgba(102, 126, 234, 0.4)",
    },
    secondary: {
      background: isDark ? "rgba(255, 255, 255, 0.1)" : "rgba(0, 0, 0, 0.05)",
      color: isDark ? "#f1f5f9" : "#1e293b",
      border: `2px solid ${
        isDark ? "rgba(255, 255, 255, 0.2)" : "rgba(0, 0, 0, 0.1)"
      }`,
      boxShadow: "none",
    },
    outline: {
      background: "transparent",
      color: isDark ? "#a78bfa" : "#6366f1",
      border: `2px solid ${isDark ? "#a78bfa" : "#6366f1"}`,
      boxShadow: "none",
    },
    ghost: {
      background: "transparent",
      color: isDark ? "#cbd5e1" : "#64748b",
      border: "none",
      boxShadow: "none",
    },
    danger: {
      background: "linear-gradient(135deg, #ef4444 0%, #dc2626 100%)",
      color: "white",
      border: "none",
      boxShadow: "0 8px 32px rgba(239, 68, 68, 0.4)",
    },
  };

  const buttonStyle = {
    ...sizes[size],
    ...variants[variant],
    display: "inline-flex",
    alignItems: "center",
    justifyContent: "center",
    gap: "8px",
    borderRadius: "12px",
    fontWeight: "600",
    cursor: disabled || loading ? "not-allowed" : "pointer",
    transition: "all 0.3s cubic-bezier(0.4, 0, 0.2, 1)",
    opacity: disabled ? 0.5 : 1,
    width: fullWidth ? "100%" : "auto",
    position: "relative",
    overflow: "hidden",
    textDecoration: "none",
    transform: isPressed
      ? "scale(0.98)"
      : isHovered
      ? "translateY(-2px)"
      : "translateY(0)",
    ...style,
  };

  const content = (
    <>
      {loading && (
        <div
          style={{
            width: "16px",
            height: "16px",
            border: "2px solid transparent",
            borderTop: "2px solid currentColor",
            borderRadius: "50%",
            animation: "spin 1s linear infinite",
          }}
        />
      )}
      {!loading && icon && iconPosition === "left" && <span>{icon}</span>}
      <span>{children}</span>
      {!loading && icon && iconPosition === "right" && <span>{icon}</span>}

      <style jsx>{`
        @keyframes spin {
          to {
            transform: rotate(360deg);
          }
        }
      `}</style>
    </>
  );

  const eventHandlers = {
    onMouseEnter: () => !disabled && setIsHovered(true),
    onMouseLeave: () => {
      setIsHovered(false);
      setIsPressed(false);
    },
    onMouseDown: () => !disabled && setIsPressed(true),
    onMouseUp: () => setIsPressed(false),
    onClick: disabled || loading ? undefined : onClick,
    ...props,
  };

  if (href) {
    return (
      <a
        href={href}
        target={target}
        style={buttonStyle}
        className={className}
        {...eventHandlers}
      >
        {content}
      </a>
    );
  }

  return (
    <button
      style={buttonStyle}
      className={className}
      disabled={disabled || loading}
      {...eventHandlers}
    >
      {content}
    </button>
  );
};
