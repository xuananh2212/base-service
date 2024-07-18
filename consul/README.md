# steps to config consul dc

1.  Step 1: Create + run DC containers
    - docker-compose up -d --build
2.  Step 2: Create the bootstrap token

    - docker exec -it consul-server1 /bin/sh
    - consul acl bootstrap

             example response:
             AccessorID: efde76d5-6e7a-2ab4-22d5-7d3adfbfeb46
             SecretID: a181aca3-b973-9dc7-8529-020920394a7b
             Description: Bootstrap Token (Global Management)
             Local: false Create Time: 2021-10-11 04:53:13.740801121 +0000
             UTC Policies: 00000000-0000-0000-0000-000000000001 - global-management

    - consul members -token "SecretID"

    - export CONSUL_HTTP_TOKEN=SecretID

    - add the agent token to all Consul agent

    - consul acl set-agent-token agent "SecretID"

    - consul reload -token "SecretID"

    - consul acl policy create -name "agent-token" -description "Agent Token Policy" -rules @/etc/consul.d/agent-policy.hcl

    - consul acl token update -id 00000000-0000-0000-0000-000000000002 -policy-name agent-token

steps to generate Self Certificate Authority

1.  Create the SSL

    - mkdir /etc/consul.d/ssl
    - mkdir /etc/consul.d/ssl/CA
    - chmod 0700 /etc/consul.d/ssl/CA
    - cd /etc/consul.d/ssl/CA
    - echo "000a" > serial
    - touch certindex
    - openssl req -x509 -newkey rsa:2048 -days 3650 -nodes -out ca.cert
    - content:
      Country Name (2 letter code) [AU]:US
      State or Province Name (full name) [Some-State]:New York
      Locality Name (eg, city) []:New York City
      Organization Name (eg, company) [Internet Widgits Pty Ltd]:DigitalOcean
      Organizational Unit Name (eg, section) []:
      Common Name (e.g. server FQDN or YOUR name) []:ConsulCA
      Email Address []:admin@example.com
    - openssl req -newkey rsa:1024 -nodes -out consul.csr -keyout consul.key
      .. Country Name (2 letter code) [AU]:US
      State or Province Name (full name) [Some-State]:New York
      Locality Name (eg, city) []:New York City
      Organization Name (eg, company) [Internet Widgits Pty Ltd]:DigitalOcean
      Organizational Unit Name (eg, section) []:
      Common Name (e.g. server FQDN or YOUR name) []:\*.example.com
      Email Address []:admin@example.com

            Please enter the following 'extra' attributes
            to be sent with your certificate request
            A challenge password []:
            An optional company name []:

      - nano /etc/consul.d/ssl/CA/myca.conf
        subjectKeyIdentifier = hash
        authorityKeyIdentifier = keyid:always,issuer:always
        basicConstraints = CA:TRUE
        keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment, keyAgreement, keyCertSign
        subjectAltName = DNS:server.dc1.consul, DNS:\*.server.dc1.consul
        issuerAltName = issuer:copy

            [ ca ]
            default_ca = myca

            [ myca ]
            unique_subject = no
            new_certs_dir = .
            certificate = ca.cert
            database = certindex
            private_key = privkey.pem
            serial = serial
            default_days = 3650
            default_md = sha1
            policy = myca_policy
            x509_extensions = myca_extensions

            [ myca_policy ]
            commonName = supplied
            stateOrProvinceName = supplied
            countryName = supplied
            emailAddress = optional
            organizationName = supplied
            organizationalUnitName = optional

            [ myca_extensions ]
            basicConstraints = CA:false
            subjectKeyIdentifier = hash
            subjectAltName = DNS:server.dc1.consul, DNS:\*.server.dc1.consul
            issuerAltName = issuer:copy
            authorityKeyIdentifier = keyid:always
            keyUsage = digitalSignature,keyEncipherment
            extendedKeyUsage = serverAuth,clientAuth

        - openssl ca -batch -config myca.conf -notext -in consul.csr -out consul.cert
        - {
          "bootstrap": true,
          "server": true,
          "datacenter": "nyc2",
          "data_dir": "/var/consul",
          "encrypt": "pmsKacTdVOb4x8/Vtr9PWw==",
          "ca_file": "/etc/consul.d/ssl/ca.cert",
          "cert_file": "/etc/consul.d/ssl/consul.cert",
          "key_file": "/etc/consul.d/ssl/consul.key",
          "log_level": "INFO",
          "enable_syslog": true
          }
