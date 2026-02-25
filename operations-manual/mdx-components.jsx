import React from 'react'
import { useMDXComponents as getDocsMDXComponents } from 'nextra-theme-docs'

// Hack for "React is not defined" error in Nextra 4 + App Router
if (typeof global !== 'undefined' && !global.React) {
  global.React = React;
}

const docsComponents = getDocsMDXComponents()

export function useMDXComponents(components) {
  return {
    ...docsComponents,
    ...components
  }
}
