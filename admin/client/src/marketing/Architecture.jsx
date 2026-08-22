import { useMemo } from 'react';
import ReactFlow, { Background, BackgroundVariant, Controls, Handle, MarkerType, Position, useEdgesState, useNodesState } from 'reactflow';
import Highlighter from './Highlighter';

const initialNodes = [
  { id: 'field', type: 'architecture', position: { x: 0, y: 190 }, data: { icon: '◉', eyebrow: 'FIELD DEVICE', title: 'MeshSetu mobile app', detail: 'SOS saved locally', tone: 'signal' } },
  { id: 'mesh', type: 'architecture', position: { x: 218, y: 72 }, data: { icon: '⌁', eyebrow: 'OFFLINE TRANSPORT', title: 'BLE relay mesh', detail: 'Store + forward', tone: 'mesh' } },
  { id: 'voice', type: 'architecture', position: { x: 218, y: 365 }, data: { icon: '◌', eyebrow: 'VOICE EVIDENCE', title: 'Voice-note chunks', detail: 'Captured + relayed', tone: 'voice' } },
  { id: 'rooms', type: 'architecture', position: { x: 438, y: 24 }, data: { icon: '◫', eyebrow: 'LIVE ROOMS', title: 'Room service', detail: 'Scoped member updates', tone: 'rooms' } },
  { id: 'gateway', type: 'architecture', position: { x: 438, y: 230 }, data: { icon: '↗', eyebrow: 'LOCAL HANDOFF', title: 'Gateway device', detail: 'Verified uplink', tone: 'gateway' } },
  { id: 'api', type: 'architecture', position: { x: 656, y: 230 }, data: { icon: '▦', eyebrow: 'SERVICE LAYER', title: 'Incident API', detail: 'Verify + route SOS', tone: 'service' } },
  { id: 'dashboard', type: 'architecture', position: { x: 892, y: 68 }, data: { icon: '▤', eyebrow: 'OPERATIONS', title: 'Control room', detail: 'Live incident view', tone: 'control' } },
  { id: 'contacts', type: 'architecture', position: { x: 892, y: 348 }, data: { icon: '↗', eyebrow: 'ESCALATION', title: 'Emergency contacts', detail: 'SMS notification', tone: 'contacts' } },
];

const initialEdges = [
  { id: 'field-mesh', source: 'field', target: 'mesh', type: 'smoothstep', animated: true, markerEnd: { type: MarkerType.ArrowClosed }, label: 'BLE', labelStyle: { fill: '#b5b2b2', fontSize: 9 }, style: { stroke: '#fe1e34', strokeWidth: 1.5 } },
  { id: 'mesh-gateway', source: 'mesh', target: 'gateway', type: 'smoothstep', animated: true, markerEnd: { type: MarkerType.ArrowClosed }, label: 'relay', labelStyle: { fill: '#b5b2b2', fontSize: 9 }, style: { stroke: '#a5a2a2', strokeWidth: 1.25 } },
  { id: 'mesh-api', source: 'mesh', target: 'api', type: 'smoothstep', animated: true, markerEnd: { type: MarkerType.ArrowClosed }, label: 'uplink', labelStyle: { fill: '#b5b2b2', fontSize: 9 }, style: { stroke: '#8f8bff', strokeWidth: 1.25 } },
  { id: 'field-voice', source: 'field', target: 'voice', type: 'smoothstep', animated: true, markerEnd: { type: MarkerType.ArrowClosed }, label: 'record', labelStyle: { fill: '#b5b2b2', fontSize: 9 }, style: { stroke: '#fe1e34', strokeWidth: 1.25 } },
  { id: 'voice-gateway', source: 'voice', target: 'gateway', type: 'smoothstep', animated: true, markerEnd: { type: MarkerType.ArrowClosed }, label: 'chunks', labelStyle: { fill: '#b5b2b2', fontSize: 9 }, style: { stroke: '#d4d2d2', strokeWidth: 1.25 } },
  { id: 'field-rooms', source: 'field', target: 'rooms', type: 'smoothstep', animated: true, markerEnd: { type: MarkerType.ArrowClosed }, label: 'join', labelStyle: { fill: '#b5b2b2', fontSize: 9 }, style: { stroke: '#8f8bff', strokeWidth: 1.25 } },
  { id: 'rooms-api', source: 'rooms', target: 'api', type: 'smoothstep', animated: true, markerEnd: { type: MarkerType.ArrowClosed }, label: 'room events', labelStyle: { fill: '#b5b2b2', fontSize: 9 }, style: { stroke: '#8f8bff', strokeWidth: 1.25 } },
  { id: 'gateway-api', source: 'gateway', target: 'api', type: 'smoothstep', animated: true, markerEnd: { type: MarkerType.ArrowClosed }, label: 'HTTPS', labelStyle: { fill: '#b5b2b2', fontSize: 9 }, style: { stroke: '#70d5b0', strokeWidth: 1.25 } },
  { id: 'api-dashboard', source: 'api', target: 'dashboard', type: 'smoothstep', animated: true, markerEnd: { type: MarkerType.ArrowClosed }, label: 'WebSocket', labelStyle: { fill: '#b5b2b2', fontSize: 9 }, style: { stroke: '#b7c5df', strokeWidth: 1.25 } },
  { id: 'api-contacts', source: 'api', target: 'contacts', type: 'smoothstep', animated: true, markerEnd: { type: MarkerType.ArrowClosed }, label: 'SMS', labelStyle: { fill: '#b5b2b2', fontSize: 9 }, style: { stroke: '#fe1e34', strokeWidth: 1.25 } },
];

function ArchitectureNode({ data }) {
  return <div className={`architecture-flow-node architecture-flow-node--${data.tone}`}>
    <Handle type="target" position={Position.Left} />
    <span><i>{data.icon}</i>{data.eyebrow}</span><strong>{data.title}</strong><small>{data.detail}</small>
    <Handle type="source" position={Position.Right} />
  </div>;
}

const nodeTypes = { architecture: ArchitectureNode };

function ArchitectureFlow() {
  const [nodes, , onNodesChange] = useNodesState(initialNodes);
  const [edges, , onEdgesChange] = useEdgesState(initialEdges);
  const flowNodeTypes = useMemo(() => nodeTypes, []);

  return <div className="architecture__flow-shell" aria-label="MeshSetu architecture flow">
    <ReactFlow nodes={nodes} edges={edges} onNodesChange={onNodesChange} onEdgesChange={onEdgesChange} nodeTypes={flowNodeTypes} fitView fitViewOptions={{ padding: 0.16 }} minZoom={0.55} maxZoom={1.4} nodesConnectable={false} proOptions={{ hideAttribution: true }}>
      <Background variant={BackgroundVariant.Lines} gap={21} size={1} color="rgba(252,252,252,.1)" />
      <Controls showInteractive={false} />
    </ReactFlow>
  </div>;
}

export default function Architecture() {
  return <section className="architecture" id="architecture">
    <div className="container">
      <div className="section-heading section-heading--split"><div><p className="section-label">System design</p><h2>Architecture</h2></div><p>A field SOS stays local until nearby phones relay it to a gateway. From there, the incident service <Highlighter action="highlight" color="#fe1e34">verifies and routes</Highlighter> it to operators and the people who need to know.</p></div>
      <ArchitectureFlow />
    </div>
  </section>;
}
