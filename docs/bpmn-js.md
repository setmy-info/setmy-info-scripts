# bpmn-js

A web-based BPMN 2.0 diagramming and modeling library written in JavaScript.

## What is bpmn-js?

**bpmn-js** is an extensible, web-based toolkit for viewing, modeling, and annotating BPMN 2.0 diagrams directly in the browser. Maintained by [bpmn.io](https://bpmn.io/) (an open-source project by Camunda), it renders standard BPMN 2.0 process definitions as vector graphics (SVG) and provides rich interactive editing capabilities without requiring server-side rendering or proprietary browser plugins.

Under the hood, bpmn-js is built on two primary modular foundations:
- **`diagram-js`**: The foundational graphical interaction engine responsible for rendering canvas layers, handling user interactions (drag, drop, zoom, pan), selection, overlays, and command stack / undo-redo mechanics.
- **`bpmn-moddle`**: A meta-model wrapper that parses, validates, instantiates, and serializes BPMN 2.0 XML schema definitions into JavaScript objects (and vice versa).

---

## What is it for?

`bpmn-js` is designed for applications and platforms that require visualization, editing, or monitoring of business workflows and automated processes:

1. **Interactive BPMN Viewing**:
   - Embedding read-only process flows in documentation, portals, dashboards, or wikis.
   - Enabling smooth panning, semantic zooming, and diagram element search.

2. **Visual Process Modeling & Workflow Design**:
   - Authoring BPMN 2.0 diagrams via an interactive palette, contextual action pads, auto-placement, and keyboard shortcuts.
   - Building custom workflow designers for orchestration engines (e.g., Camunda, Zeebe, Temporal, custom backends).

3. **Workflow Monitoring & Process Analytics**:
   - Adding visual badges, execution heatmaps, step counts, and status overlays over active process instances.
   - Highlighting currently running tokens, failed steps, or completed activity nodes in live pipelines.

4. **Domain-Specific Extensions & Custom Rule Engines**:
   - Creating custom element renderers and custom shapes (e.g., service tasks with proprietary branding).
   - Adding custom business rules, validation constraints, and XML schema extensions for vendor attributes.

---

## Distributions / Flavors

`bpmn-js` is distributed in three main variants depending on application needs:

| Distribution | Import / Class | Description | Typical Use Case |
|---|---|---|---|
| **Viewer** | `BpmnViewer` (`bpmn-js/lib/Viewer`) | Read-only static SVG renderer without navigation controls. | Static documentation, report embedding, and lightweight thumbnails. |
| **NavigatedViewer** | `BpmnNavigatedViewer` (`bpmn-js/lib/NavigatedViewer`) | Read-only SVG renderer with interactive canvas navigation (pan, zoom, mouse wheel, element selection). | Interactive process dashboards, audit views, and live instance monitoring. |
| **Modeler** | `BpmnModeler` (`bpmn-js/lib/Modeler`) | Complete interactive editor with tool palette, context pads, shape placement, connecting, property editing, undo/redo (`CommandStack`), and keyboard bindings. | Workflow designers, process authoring tools, and low-code orchestrator builders. |

---

## Key Links & Resources

- **Official Website**: [https://bpmn.io/toolkit/bpmn-js/](https://bpmn.io/toolkit/bpmn-js/)
- **Interactive Live Modeler (Demo)**: [https://demo.bpmn.io/](https://demo.bpmn.io/)
- **GitHub Repository**: [https://github.com/bpmn-io/bpmn-js](https://github.com/bpmn-io/bpmn-js)
- **Official Walkthrough & API Guide**: [https://bpmn.io/toolkit/bpmn-js/walkthrough/](https://bpmn.io/toolkit/bpmn-js/walkthrough/)
- **Examples Repository**: [https://github.com/bpmn-io/bpmn-js-examples](https://github.com/bpmn-io/bpmn-js-examples)
- **bpmn.io Community Forum**: [https://forum.bpmn.io/](https://forum.bpmn.io/)
- **Underlying Diagram Engine (`diagram-js`)**: [https://github.com/bpmn-io/diagram-js](https://github.com/bpmn-io/diagram-js)
- **BPMN 2.0 Metamodel AST (`bpmn-moddle`)**: [https://github.com/bpmn-io/bpmn-moddle](https://github.com/bpmn-io/bpmn-moddle)

---

## Quick Start

### Installation

```bash
npm install bpmn-js
```

Ensure required CSS stylesheets are included in your bundle or HTML:
```css
@import 'bpmn-js/dist/assets/diagram-js.css';
@import 'bpmn-js/dist/assets/bpmn-js.css';
@import 'bpmn-js/dist/assets/bpmn-font/css/bpmn.css';
```

### Basic Embedding Example (JavaScript / Modeler)

```javascript
import BpmnModeler from 'bpmn-js/lib/Modeler';

const modeler = new BpmnModeler({
  container: '#canvas',
  keyboard: {
    bindTo: document
  }
});

async function openDiagram(xml) {
  try {
    const { warnings } = await modeler.importXML(xml);
    if (warnings.length) {
      console.warn('Import warnings:', warnings);
    }
    const canvas = modeler.get('canvas');
    canvas.zoom('fit-viewport');
  } catch (err) {
    console.error('Failed to import BPMN 2.0 XML:', err, err.warnings);
  }
}

async function exportDiagram() {
  try {
    const { xml } = await modeler.saveXML({ format: true });
    console.log('Exported XML:', xml);
  } catch (err) {
    console.error('Failed to export XML:', err);
  }
}
```
