const axios = require('axios');
let response;
let AUTH0_DOMAIN = process.env.AUTH0_DOMAIN;
let AUTH0_CLIENT_ID = process.env.AUTH0_CLIENT_ID;
let AUTH0_CLIENT_SECRET = process.env.AUTH0_CLIENT_SECRET;
let AUTH0_AUDIENCE = process.env.AUTH0_AUDIENCE;
let AUTH0_API2_CLIENT_ID = process.env.AUTH0_API2_CLIENT_ID;
let AUTH0_API2_CLIENT_SECRET = process.env.AUTH0_API2_CLIENT_SECRET;
let AUTH0_ACTIONS_ID = process.env.AUTH0_ACTIONS_ID;

/**
 *
 * Event doc: https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html#api-gateway-simple-proxy-for-lambda-input-format
 * @param {Object} event - API Gateway Lambda Proxy Input Format
 *
 * Context doc: https://docs.aws.amazon.com/lambda/latest/dg/nodejs-prog-model-context.html
 * @param {Object} context
 *
 * Return doc: https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html
 * @returns {Object} object - API Gateway Lambda Proxy Output Format
 *
 */
exports.lambdaHandler = async (event, context) => {
    try {

        // [1] Get M2M Access Token for Custom API
        let tokenEndpoint = `https://${AUTH0_DOMAIN}/oauth/token`;
        let clientCredentialsRequest = {
            client_id: AUTH0_CLIENT_ID,
            client_secret: AUTH0_CLIENT_SECRET,
            audience: AUTH0_AUDIENCE,
            grant_type: "client_credentials"
        };

        let options = {
            method: 'POST',
            url: tokenEndpoint,
            headers: { 'content-type': 'application/json' },
            data: clientCredentialsRequest
        };

        let tokenResponse = await axios(options);
        let m2mAccessToken = tokenResponse.data.access_token;

        // [2] Get Access Token for Auth0 Management API
        clientCredentialsRequest = {
            client_id: AUTH0_API2_CLIENT_ID,
            client_secret: AUTH0_API2_CLIENT_SECRET,
            audience: `https://${AUTH0_DOMAIN}/api/v2/`,
            grant_type: "client_credentials"
        };

        options = {
            method: 'POST',
            url: tokenEndpoint,
            headers: { 'content-type': 'application/json' },
            data: clientCredentialsRequest
        };

        tokenResponse = await axios(options);
        let mgmtApiAccessToken = tokenResponse.data.access_token;

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
            headers: {
                'Authorization': 'Bearer ' + mgmtApiAccessToken,
                'Content-Type': 'application/json',
            },
            data: actionsSecretRequest
        }

        response = await axios(options);
    } catch (err) {
        console.log(`oops: ${err}`);
        return err;
    }

    return {
        'statusCode': 200
    };
};
