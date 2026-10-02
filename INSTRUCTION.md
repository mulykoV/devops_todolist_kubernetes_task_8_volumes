# ToDo App Kubernetes Deployment — Validation Instructions

This document describes how to deploy and validate the ToDo application in a Kubernetes cluster.

## 1. Deploy the application

Deploy all required Kubernetes resources using the bootstrap script:

```bash
chmod +x bootstrap.sh
./bootstrap.sh
```

Alternatively, the Kubernetes resources can be applied manually:

```bash
kubectl apply -f namespace.yml
kubectl apply -f pv.yml
kubectl apply -f pvc.yml
kubectl apply -f configmap.yml
kubectl apply -f secret.yml
kubectl apply -f deployment.yml
kubectl apply -f service.yml
```

> The exact list of files may depend on the existing project structure.

---

## 2. Validate that the application is running

Check the Pods in the `todoapp` namespace:

```bash
kubectl get pods -n todoapp
```

The ToDo application Pod should have the `Running` status and should be ready:

```text
NAME                       READY   STATUS    RESTARTS   AGE
todoapp-xxxxxxxxxx-xxxxx    1/1     Running   0          1m
```

Check the Deployment:

```bash
kubectl get deployment -n todoapp
```

Expected result:

```text
NAME      READY   UP-TO-DATE   AVAILABLE
todoapp   1/1     1            1
```

To see detailed information about the Deployment:

```bash
kubectl describe deployment todoapp -n todoapp
```

---

## 3. Validate PersistentVolume and PersistentVolumeClaim

Check the PersistentVolume:

```bash
kubectl get pv
```

The `todoapp-pv` PersistentVolume should be available or bound to the PersistentVolumeClaim.

Check the PersistentVolumeClaim:

```bash
kubectl get pvc -n todoapp
```

The expected PVC status is:

```text
NAME          STATUS   VOLUME       CAPACITY   ACCESS MODES   STORAGECLASS
todoapp-pvc   Bound    todoapp-pv   1Gi        RWX            standard
```

The important value is:

```text
STATUS: Bound
```

This means that the PersistentVolumeClaim is successfully connected to the PersistentVolume.

---

## 4. Validate PersistentVolume mount

Get the name of the running Pod:

```bash
kubectl get pods -n todoapp
```

Then check that the persistent storage is mounted to `/app/data`:

```bash
kubectl exec -n todoapp <pod-name> -- ls -la /app/data
```

For example:

```bash
kubectl exec -n todoapp todoapp-xxxxxxxxxx-xxxxx -- ls -la /app/data
```

The `/app/data` directory should exist inside the container.

The storage chain is:

```text
/app/data
    ↓
todoapp-pvc
    ↓
todoapp-pv
    ↓
hostPath: /mnt/data
```

---

## 5. Validate ConfigMap mount

The existing `app-config` ConfigMap is mounted as files into:

```text
/app/configs
```

Check the mounted files:

```bash
kubectl exec -n todoapp <pod-name> -- ls -la /app/configs
```

The directory should contain:

```text
PYTHONUNBUFFERED
```

Check the content of the mounted ConfigMap file:

```bash
kubectl exec -n todoapp <pod-name> -- cat /app/configs/PYTHONUNBUFFERED
```

Expected output:

```text
1
```

The ConfigMap is mounted as read-only.

---

## 6. Validate Secret mount

The existing `app-secret` Secret is mounted as files into:

```text
/app/secrets
```

Check that the Secret file exists:

```bash
kubectl exec -n todoapp <pod-name> -- ls -la /app/secrets
```

The directory should contain:

```text
SECRET_KEY
```

To verify that the file contains data without printing the secret value, run:

```bash
kubectl exec -n todoapp <pod-name> -- sh -c 'test -s /app/secrets/SECRET_KEY && echo "SECRET_KEY file exists and is not empty"'
```

Expected output:

```text
SECRET_KEY file exists and is not empty
```

The Secret is mounted as read-only.

---

## 7. Validate mounted volumes

To see all volumes and volume mounts configured for the Pod:

```bash
kubectl describe pod -n todoapp <pod-name>
```

The Pod should contain the following mounts:

```text
/app/data
/app/configs
/app/secrets
```

Where:

- `/app/data` uses the `todoapp-pvc` PersistentVolumeClaim.
- `/app/configs` contains files from the `app-config` ConfigMap.
- `/app/secrets` contains files from the `app-secret` Secret.

---

## 8. Check application logs

Application logs can be checked with:

```bash
kubectl logs -n todoapp <pod-name>
```

The application should start successfully without errors related to volumes, ConfigMap, or Secret mounts.

---

## Expected result

After successful deployment:

```text
ToDo Deployment
│
└── Pod
    │
    ├── /app/data
    │      └── PVC: todoapp-pvc
    │             └── PV: todoapp-pv
    │
    ├── /app/configs
    │      └── ConfigMap: app-config
    │
    └── /app/secrets
           └── Secret: app-secret
```

The application Pod should be running, the `todoapp-pvc` should have the `Bound` status, the ConfigMap data should be available as files in `/app/configs`, and the Secret data should be available as files in `/app/secrets`.