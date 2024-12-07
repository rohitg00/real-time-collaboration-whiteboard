// Simple consensus implementation
class Consensus {
    constructor() {
        this.nodes = new Map();
        this.leader = null;
        this.term = 0;
    }

    addNode(nodeId) {
        this.nodes.set(nodeId, {
            id: nodeId,
            lastHeartbeat: Date.now(),
            state: 'follower'
        });

        if (!this.leader) {
            this.leader = nodeId;
            this.nodes.get(nodeId).state = 'leader';
        }
    }

    removeNode(nodeId) {
        this.nodes.delete(nodeId);
        if (this.leader === nodeId) {
            this.electNewLeader();
        }
    }

    electNewLeader() {
        if (this.nodes.size > 0) {
            this.term++;
            const nodeIds = Array.from(this.nodes.keys());
            this.leader = nodeIds[0];
            this.nodes.get(this.leader).state = 'leader';
        } else {
            this.leader = null;
        }
    }

    isLeader(nodeId) {
        return this.leader === nodeId;
    }

    heartbeat(nodeId) {
        if (this.nodes.has(nodeId)) {
            this.nodes.get(nodeId).lastHeartbeat = Date.now();
        }
    }
}

module.exports = new Consensus(); 