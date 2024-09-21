# Metrics

Using **Resource**, **Event Type**, and **Event Action** as part of a structured metric system for GitHub activities is used as a logical and flexible approach.

### 1. **Resource**

- This would represent the primary entity or object in GitHub, like a Pull Request, Issue, Gist, Artifact, or Check.
- **Examples**:
  - `Pull Request`
  - `Issue`
  - `Gist`
  - `Artifact`
  - `Check`
  - `Organization`

### 2. **Event Type**

- This would describe what kind of event or interaction is happening around the resource, such as a **Comment**, **Review**, or **Label**.
- **Examples**:
  - `Comment`
  - `Review`
  - `Label`
  - `Assignment`
  - `Approval`
  - `Merge`

### 3. **Event Action**

- This would define the specific action being taken on the resource in that event, such as **Creating**, **Deleting**, or **Updating**.
- **Examples**:
  - `Create`
  - `Delete`
  - `Update`
  - `Approve`
  - `Request Changes`
  - `Close`

### Example Usage

- A Pull Request being created:
  - **Resource**: `Pull Request`
  - **Event Type**: `Creation`
  - **Event Action**: `Create`

- A comment being added to an issue:
  - **Resource**: `Issue`
  - **Event Type**: `Comment`
  - **Event Action**: `Create`

- A review approving a pull request:
  - **Resource**: `Pull Request`
  - **Event Type**: `Review`
  - **Event Action**: `Approve`

This structure is clear, extensible, and provides a logical way to model different GitHub activities. It allows you to define metrics and events in a consistent manner across various resources and actions. Would you like to fine-tune any part of this further?
