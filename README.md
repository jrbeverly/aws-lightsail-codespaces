# Running code-server on AWS Lightsail

## Summary

Run VS Code on an AWS Lightsail instance with auto-generated password and static IP. Early experiments with cloud-driven development environments configured on-demand using terraform.

Initial exploratory work for seeing what changes exist in the workflows, and any issues that may arise as a result of working in Lightsail.

## Notes

Below are some quick points noted while experimenting with this:

### AWS Access Keys

In comparison to running this on ECS or EC2, AWS access keys [need to be generated and supplied](https://lightsail.aws.amazon.com/ls/docs/en_us/articles/lightsail-how-to-set-up-access-keys-to-use-sdk-api-cli) if you wish to run AWS commands.

This is nice to some degree if I rely on aws sso to have temporary credentials. Each instance can then focus on being configured for `aws sso` (or related sso tooling) to get keys.

Pulling data from the instance would be an issue, and make cross-cutting concerns (like backups / logging) more difficult.

### Baked Images

Unlike ECS or EC2, it doesn't offer the options of pre-baking an image. That would be ideal, as it would allow for layering (base -> developer -> devops -> admin) that has the minimum necessary tools and recommended specs. Branching could also be an option depending on the type of workloads (perf, load, cross-browser validation).

Provisioning with a single shell script works fine for the demo, but a fully featured environment would need something like ansible.

### Ports

Terraform doesn't support defining the ports at this time, and requires a workaround mechanism. This isn't ideal, and makes it difficult to have a more flexible model.

Manual modification of the firewall is less than ideal, as the desired intent is to be completely automated. In this way running in an ECS/EC2 environment is superior as it allows for restricting incoming traffic to just the VPN. Ports can then be exposed in blocks without risking open internet access.

## Overall Thoughts

AWS Lightsail doesn't really scale to the desired solution. I'd like something that allows public access but can be locked behind sufficient guardrails (such as a VPN + SSO).

Working with terraform to provision the environment is nice, and with a gitops approach could make provisioning dev environments on demand really easy.

Defining the environments may encounter some problems, as I'd like to avoid YAML sprawl when figuring out what should be on the instance.
