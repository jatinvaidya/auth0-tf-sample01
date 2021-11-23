const axios = require('axios');
const { SecretsManagerClient, GetSecretValueCommand } = require("@aws-sdk/client-secrets-manager");
let response;
let AUTH0_DOMAIN = process.env.AUTH0_DOMAIN;
let AUTH0_CLIENT_ID = process.env.AUTH0_CLIENT_ID;
let AUTH0_CLIENT_SECRET_ARN = process.env.AUTH0_CLIENT_SECRET_ARN;
let AUTH0_AUDIENCE = process.env.AUTH0_AUDIENCE;
let AUTH0_API2_CLIENT_ID = process.env.AUTH0_API2_CLIENT_ID;
let AUTH0_API2_CLIENT_SECRET_ARN = process.env.AUTH0_API2_CLIENT_SECRET_ARN;
let AUTH0_ACTIONS_ID = process.env.AUTH0_ACTIONS_ID;

const smClient = new SecretsManagerClient({ region: REGION });

async function getM2MClientSecret() {
    const data = await smClient.send(new GetSecretValueCommand({ SecretId: AUTH0_CLIENT_SECRET_ARN }));
    return 'SecretString' in data ? data.SecretString : new Buffer(data.SecretBinary, 'base64').toString('ascii');
}

async function getM2MAuth0API2ClientSecret() {
    const data = await smClient.send(new GetSecretValueCommand({ SecretId: AUTH0_API2_CLIENT_SECRET_ARN }));
    return 'SecretString' in data ? data.SecretString : new Buffer(data.SecretBinary, 'base64').toString('ascii');
}

exports.lambdaHandler = async (event, context) => {
    try {

        // [1] Get M2M Access Token for Custom API
        let tokenEndpoint = `https://${AUTH0_DOMAIN}/oauth/token`;
        let clientCredentialsRequest = {
            client_id: AUTH0_CLIENT_ID,
            client_secret: await getM2MClientSecret(),
            audience: AUTH0_AUDIENCE,
            grant_type: "client_credentials"
        };

        let options = {
            method: 'POST',
            url: tokenEndpoint,
            config: { headers: { 'content-type': 'application/json' } },
            data: clientCredentialsRequest
        };

        let tokenResponse = await axios(options);
        let m2mAccessToken = tokenResponse.data.access_token;

        // [2] Get Access Token for Auth0 Management API
        clientCredentialsRequest = {
            client_id: AUTH0_API2_CLIENT_ID,
            client_secret: await getM2MAuth0API2ClientSecret(),
            audience: `https://${AUTH0_DOMAIN}/api/v2/`,
            grant_type: "client_credentials"
        };

        options = {
            method: 'POST',
            url: tokenEndpoint,
            config: { headers: { 'content-type': 'application/json' } },
            data: clientCredentialsRequest
        };

        tokenResponse = await axios(options);

        // [3] Set the M2M Access Token from Step #1 as an Actions Secret
        let actionsSecretRequest = {
            secrets: [{
                name: "m2m_token",
                value: m2mAccessToken
            }]
        };

        options = {
            method: 'PATCH',
            url: `https://${AUTH0_DOMAIN}/api/v2/actions/actions/${AUTH0_ACTIONS_ID}`,
            config: { headers: { 'content-type': 'application/json' } },
            data: actionsSecretRequest
        }

        response = {
            'statusCode': 200
        }
    } catch (err) {
        console.log(`oops: ${err}`);
        return err;
    }

    return response
};
