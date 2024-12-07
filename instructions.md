# Distributed Systems Assignment: Private Cloud Whiteboard Application

You have to design and document the architecture of a private cloud, implement it, and then
deploy on it a whiteboard application. The whiteboard application should run on at least two
separate machines/nodes within your private cloud, with each application’s instance serving
a different group of users. You should demonstrate that the distributed application running in
your private cloud is consistent in a way that all users will see the same application state
across different instances. The cloud and application should scale to support additional users,
and offer an improved quality of service when compared to one running on a single machine.
The assignment is separated into a set of tasks, and there is a set of activities that should be
undertaken for each task.
You are not restricted to a particular set of tools or technologies, but you must justify your
choices when designing and implementing your architecture. You should critically assess your
options before you propose your architecture and carefully evaluate the tools and technologies
to implement your architectur

## Assignment Brief
Design, document, and implement a private cloud architecture to deploy a distributed whiteboard application. The application should:
- Run on multiple nodes within your private cloud
- Serve different user groups across instances
- Maintain consistency across all instances
- Scale to support additional users
- Provide improved quality of service compared to single-machine deployment

## Submission Details
- Group size: Maximum 4 members
- Individual submission: Written report (90% of grade)
- Group submission: Video demonstration

## Task 1: Private Cloud Design [20%]
Design and architect a private cloud infrastructure that provides:
- Consistency mechanisms
- Scalability features
- Agility in deployment
- Quality of service guarantees
- Fault-tolerant network topology

**Individual Requirements:**
- Explain the design choices
- Justify technology selections
- Include architecture diagram

## Task 2: Private Cloud Implementation [30%]
Implement the designed architecture with:
- Consistent data access
- Scalable resources
- Low-latency performance
- Automated provisioning
- Minimal human intervention
- Multi-node deployment
- Distributed whiteboard instances

**Individual Requirements:**
- Document implementation details
- Explain environment setup
- Detail component interactions
- Describe code functionality

## Task 3: Distributed Whiteboard Application [20%]
Develop a whiteboard application with:
- Multi-node distribution
- Real-time drawing features
- Simultaneous multi-user support
- State synchronization
- Consistent view across instances

**Features Required:**
- Basic drawing tools (lines, shapes)
- Text insertion
- Shared interactive canvas
- State preservation
- Real-time updates

**Individual Requirements:**
- Explain application design
- Document consistency mechanisms
- Detail replication strategy
- Describe state management

## Task 4: System Demonstration [10%]
**Group Video Requirements:**
- Showcase cloud functionality
- Highlight individual contributions
- Demonstrate resource monitoring:
  - Computing resources
  - Storage utilization
  - Network performance
- Show scalability metrics
- Present performance analysis

**Individual Requirements:**
- One-page contribution summary
- Component demonstration
- Implementation walkthrough

## Task 5: Critical System Review [20%]
**Individual Analysis Requirements:**

1. Architecture Review:
   - Design decisions
   - Technology choices
   - Implementation approach

2. System Analysis:
   - Design strengths
   - Implementation strengths
   - Design weaknesses
   - Implementation limitations

3. Improvement Proposals:
   - Design enhancements
   - Implementation optimizations
   - Justification for changes
   - Expected benefits

## Technology Options

### Cloud Platforms:
- Google Cloud
- OpenStack
- Amazon Web Services
- Microsoft Azure

### Hypervisors:
- XEN
- KVM
- Hyper-V
- Oracle VirtualBox

### Monitoring Tools:
- Prometheus
- Cloud Watch
- Nagios
- Grafana
- Ganglia
- NMS


## Marking Rubric

### Task 1: Private Cloud Design
| Criteria | Marginal | Satisfactory | Competent | Excellent |
| --- | --- | --- | --- | --- |
| Design Description | Basic description | Consistency or scalability | Consistency and scalability | Network topology and low-latency measures |

### Task 2: Private Cloud Implementation
| Criteria | Marginal | Satisfactory | Competent | Excellent |
| --- | --- | --- | --- | --- |
| Implementation Evidence | Working implementation | Consistency or scalability | Consistency and scalability | Scalability, consistency, and low-latency measures |

### Task 3: Distributed Whiteboard Application
| Criteria | Marginal | Satisfactory | Competent | Excellent |
| --- | --- | --- | --- | --- |
| Application Deployment | Basic attempt | Standalone application | Distributed application | Consistent instances with state synchronization |

### Task 4: System Demonstration
| Criteria | Marginal | Satisfactory | Competent | Excellent |
| --- | --- | --- | --- | --- |
| Video Quality | Poor demonstration | Good demonstration | Strong individual contributions | Perfectly working system |

### Task 5: Critical System Review
| Criteria | Marginal | Satisfactory | Competent | Excellent |
| --- | --- | --- | --- | --- |
| Review Quality | Minimal attempt | Basic review | Strong review with reasons | Solid roadmap for improvement |