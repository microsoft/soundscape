// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

import Axios from 'axios';

const axios = Axios.create({
  baseURL: '/.auth',
  headers: {
    'content-type': 'application/json',
  },
});

class Auth {
  constructor() {
    this.authResponse = null;
    this.userId = null;
    this.userEmail = null;
    this.userName = null;
    this.preferredUsername = null;
    this.idToken = null;
  }

  get isAuthenticated() {
    return this.authResponse != null;
  }

  async fetchAuthInfo() {
    let res = await axios.get('me');
    res = res.data;

    const userId = Auth.valueForClaimType(res, 'http://schemas.microsoft.com/identity/claims/objectidentifier');
    const userEmail = Auth.valueForClaimType(res, 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress');
    const userName = Auth.valueForClaimType(res, 'name');
    const preferredUsername = Auth.valueForClaimType(res, 'preferred_username');

    if (!userId || !userName) {
      throw Error('Invalid authentication response. Should contain user ID and name.');
    }

    this.authResponse = res;
    this.userId = userId;
    this.userEmail = userEmail;
    this.userName = userName;
    this.preferredUsername = preferredUsername;

    this.idToken = res[0].id_token;

    let user = {
      userId: this.userId,
      userEmail: this.userEmail,
      userName: this.userName,
      preferredUsername: this.preferredUsername,
    };

    return user;
  }

  static valueForClaimType(authResponse, claimType) {
    if (!Array.isArray(authResponse) || authResponse.length === 0) {
      throw Error('Invalid authentication response. should contain at least one tokens object.');
    }

    const claims = authResponse[0].user_claims;
    const claim = claims.find((claim) => {
      return claim.typ === claimType;
    });

    if (!claim) {
      return null;
    }

    return claim.val;
  }
}

export default Auth;
