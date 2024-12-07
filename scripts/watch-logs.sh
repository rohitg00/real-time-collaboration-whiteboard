#!/bin/bash

echo "Watching whiteboard pod logs..."
kubectl logs -f -l app=whiteboard -n whiteboard-app --all-containers=true --since=1m --tail=50 