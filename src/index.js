const {
  SecretsManagerClient,
  GetSecretValueCommand,
} = require("@aws-sdk/client-secrets-manager");

exports.handler = async () => {
  const client = new SecretsManagerClient();
  const command = new GetSecretValueCommand({ SecretId: "SECRETS_FOOBAR" });

  const response = await client.send(command);
  console.log(response.SecretString);
};
