# Signed SSH Certificates

OpenBao can be used to [sign SSH certificates](https://openbao.org/docs/secrets/ssh/signed-ssh-certificates/) for both servers and clients. SSH certificates eliminate the need to manage authorized_keys files, reduce trust on first use warnings, and add functionality such as TTLs.

1. [Start the Example](#start-the-example)
1. [Configure the SSH Secrets Engine](#configure-the-ssh-secrets-engine)
1. [Sign SSH Client Keys](#sign-ssh-client-keys)
1. [SSH Using Signed Certificate](#ssh-using-signed-certificate)
1. [Stop the Example](#stop-the-example)

# Start the Example
1.  The example can be started as shown below.
    ```bash
    make up
    ```

    Once this completes there will be three containers running:
    - **openbao** - The OpenBao server.
    - **openssh** - The OpenSSH server.
    - **client** -  The container used to test SSH access.

    The keys used to configure OpenBao's CA have already been generated. The public key has been added to the OpenSSH server's TrustedUserCAKeys configuration and the client's known_hosts configuration.

# Configure the SSH Secrets Engine
1.  Exec into the client container using `make exec-client` and enable the SSH secrets engine.
    ```bash
    bao secrets enable -path=ssh-client-signer ssh
    ```
    <details>
    <summary>Sample output</summary>
    <pre>Success! Enabled the ssh secrets engine at: ssh-client-signer/</pre>
    </details>

1.  From within the `/keys` directory configure OpenBao with a CA for signing client keys
    ```bash
    bao write ssh-client-signer/config/ca public_key=@ca_id_rsa.pub private_key=@ca_id_rsa
    ```
    <details>
    <summary>Sample output</summary>
    <pre>
    Key            Value
    ---            -----
    issuer_id      23964702-1f05-dbd5-16ff-8dd699ac6c22
    issuer_name    n/a
    public_key     ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCtviNWyK2TbkNMh+nKfPg8pHxIE/8kOn3fNuHaQL9uz0ocRdR3GyCbBDEBgHxv0aJEkn7z3s6PKKUKpGiE4/Gub24PuuWWRgbP1/ueYRNMJZkNsyjW0YvcRR+FdWUnV3W++IhvfWzWD7skPmxn/eBL1Z7ZfY7Y6GkG99LVYpENQRXtRAqEpDJknYUzDAxXFAQyhTHJbg85Yhk18yRa7pFmzep45zHYT8/D44iU4E2zuLjntQIxCualwIUBbWVOb+NPV+2O2FQQQ/9tjfcdDFXrTsJqtPYe+lC91ODGToxFCkaEvByqtWy3lRthUILNn8hDk1hcRrfUbzMRJfaSoJZOtHFyf5MRwhpF/lntngDtBNkzJf4TVUZXrZ7zVjbO11XF0FqkSiwm1gHGxav0VI/cxSmI/EPd2K1uRBI2ohxq95OrrtBScOe/5aMeFkAu1Xxmy2+/PmvmXh93wt/7WwL3h/+4itaxngJEGWsU8wuS6wlaoy/mJgFnj+GB6MQfwKM=
    </pre>
    </details>

1.  Create a named OpenBao role for signing client keys.
    ```bash
    bao write ssh-client-signer/roles/example -<<"EOH"
    {
      "algorithm_signer": "rsa-sha2-256",
      "allow_user_certificates": true,
      "allowed_users": "*",
      "allowed_extensions": "permit-pty,permit-port-forwarding",
      "default_extensions": {
        "permit-pty": ""
      },
      "key_type": "ca",
      "default_user": "alice",
      "ttl": "2h"
    }
    EOH
    ```
    <details>
    <summary>Sample output</summary>
    <pre>Success! Data written to: ssh-client-signer/roles/example</pre>
    </details>

# Sign SSH Client Keys
We can now use the configured CA and role to sign client keys.

1.  Generate a new RSA key pair.
    ```bash
    ssh-keygen -t rsa
    ```
    <details>
    <summary>Sample output</summary>
    <pre>
    Generating public/private rsa key pair.
    Enter file in which to save the key (/root/.ssh/id_rsa): 
    Created directory '/root/.ssh'.
    Enter passphrase for "/root/.ssh/id_rsa" (empty for no passphrase): 
    Enter same passphrase again: 
    Your identification has been saved in /root/.ssh/id_rsa
    Your public key has been saved in /root/.ssh/id_rsa.pub
    The key fingerprint is:
    SHA256:zBX6Sb4zHm/YHSNTqzAFSrztQhLYNbyqcwmcXe93WhE root@564777db457b
    The key's randomart image is:
    +---[RSA 3072]----+
    |     o +o .      |
    |    . o +o..     |
    |       o.=o.  E  |
    |      .o*=... .. |
    |   . o =So+. ... |
    |    + o . =.o +. |
    |     o . o== =.o |
    |    o o  .o==.o  |
    |     o    .ooo   |
    +----[SHA256]-----+
    </pre>
    </details>

1.  Use OpenBao to sign your public key, saving the result to a file.
    ```bash
    bao write -field=signed_key ssh-client-signer/sign/example valid_principals=alice public_key=@/root/.ssh/id_rsa.pub > /root/.ssh/signed-cert.pub
    ```

1.  Inspect the signed certificate. `~/.ssh/signed-cert.pub` now contains an SSH certificate signed by OpenBao. It can be inspected using `ssk-keygen`
    ```bash
    ssh-keygen  -Lf ~/.ssh/signed-cert.pub
    ```
    <details>
    <summary>Sample output</summary>
    <pre>
    /root/.ssh/signed-cert.pub:
        Type: ssh-rsa-cert-v01@openssh.com user certificate
        Public key: RSA-CERT SHA256:zBX6Sb4zHm/YHSNTqzAFSrztQhLYNbyqcwmcXe93WhE
        Signing CA: RSA SHA256:rOiTamu9WYWbZza5VC9bEaf6C7wx8ttpGihQimvoESM (using rsa-sha2-256)
        Key ID: "vault-token-cc15fa49be331e6fd81d2353ab30054abced4212d835bcaa73099c5def775a11"
        Serial: 63294071858896598
        Valid: from 2026-05-26T01:20:08 to 2026-05-26T03:20:38
        Principals: 
                alice
        Critical Options: (none)
        Extensions: 
                permit-pty
    </pre>
    </details>

# SSH Using Signed Certificate
1. Now the signed certificate along with the corresponding private key can be used to SSH to the OpenSSH server. In this example the SSH server's public key has [already been signed](https://openbao.org/docs/secrets/ssh/signed-ssh-certificates/#host-key-signing) and the public key of the CA added to the ~/.ssh/known_hosts file. The SSH client can use the CA's public key to verify the server so there is no trust on first use warning.
    ```bash
    ssh -i ~/.ssh/id_rsa -o CertificateFile=~/.ssh/signed-cert.pub -p 2222 alice@openssh
    ```
    <details>
    <summary>Sample output</summary>
    <pre>Welcome to OpenSSH Server</pre>
    </details>

# Stop the Example
1.  Exit the client container and stop the example.
    ```bash
    make down
    ```