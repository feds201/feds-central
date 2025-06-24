import React from "react";
import Editor from "@monaco-editor/react";

function RoundedEditor(props) {
  return (
    <div style={{ borderRadius: '10px', overflow: 'hidden' }}>
      <Editor {...props} />
    </div>
  );
}

export default RoundedEditor;