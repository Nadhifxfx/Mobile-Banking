/**
 * Service Layer Client
 * Handles all HTTP requests to Service Layer (Port 8001)
 */

const axios = require('axios');

const SERVICE_URL = process.env.SERVICE_LAYER_URL || 'http://localhost:8001';

class ServiceLayerClient {
  constructor() {
    this.baseURL = SERVICE_URL;
    this.client = axios.create({
      baseURL: this.baseURL,
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json'
      }
    });
  }

  // ===== Customer Operations =====

  async getCustomerByUsername(username) {
    try {
      const response = await this.client.get(`/service/customer/username/${username}`);
      return response.data;
    } catch (error) {
      throw this.handleError(error);
    }
  }

  async getCustomerById(customerId) {
    try {
      const response = await this.client.get(`/service/customer/${customerId}`);
      return response.data;
    } catch (error) {
      throw this.handleError(error);
    }
  }

  async registerCustomer(customerData) {
    try {
      const response = await this.client.post('/service/customer', customerData);
      return response.data;
    } catch (error) {
      throw this.handleError(error);
    }
  }

  async updateCustomer(customerId, customerData) {
    try {
      const response = await this.client.put(`/service/customer/${customerId}`, customerData);
      return response.data;
    } catch (error) {
      throw this.handleError(error);
    }
  }

  async recordFailedLogin(customerId) {
    try {
      const response = await this.client.post(`/service/customer/${customerId}/failed-login`);
      return response.data;
    } catch (error) {
      throw this.handleError(error);
    }
  }

  async checkLocked(customerId) {
    try {
      const response = await this.client.get(`/service/customer/${customerId}/check-locked`);
      return response.data;
    } catch (error) {
      throw this.handleError(error);
    }
  }

  async unlockAccount(customerId) {
    try {
      const response = await this.client.post(`/service/customer/${customerId}/unlock`);
      return response.data;
    } catch (error) {
      throw this.handleError(error);
    }
  }

  // ===== Account Operations =====

  async createAccount(accountData) {
    try {
      const response = await this.client.post('/service/account', accountData);
      return response.data;
    } catch (error) {
      throw this.handleError(error);
    }
  }

  async getAccountsByCustomer(customerId, activeOnly = true) {
    try {
      const response = await this.client.get(`/service/account/customer/${customerId}`, {
        params: { active_only: activeOnly }
      });
      return response.data;
    } catch (error) {
      throw this.handleError(error);
    }
  }

  async getAccountByNumber(accountNumber) {
    try {
      const response = await this.client.get(`/service/account/number/${accountNumber}`);
      return response.data;
    } catch (error) {
      throw this.handleError(error);
    }
  }

  async getAccountBalance(accountNumber) {
    try {
      const response = await this.client.get(`/service/account/${accountNumber}/balance`);
      return response.data;
    } catch (error) {
      throw this.handleError(error);
    }
  }

  async debitAccount(accountNumber, amount) {
    try {
      const response = await this.client.post(`/service/account/${accountNumber}/debit`, null, {
        params: { amount }
      });
      return response.data;
    } catch (error) {
      throw this.handleError(error);
    }
  }

  async creditAccount(accountNumber, amount) {
    try {
      const response = await this.client.post(`/service/account/${accountNumber}/credit`, null, {
        params: { amount }
      });
      return response.data;
    } catch (error) {
      throw this.handleError(error);
    }
  }

  // ===== Transaction Operations =====

  async createTransaction(transactionData) {
    try {
      const response = await this.client.post('/service/transaction', transactionData);
      return response.data;
    } catch (error) {
      throw this.handleError(error);
    }
  }

  async getTransactionsByCustomer(customerId, skip = 0, limit = 100) {
    try {
      const response = await this.client.get(`/service/transaction/customer/${customerId}`, {
        params: { skip, limit }
      });
      return response.data;
    } catch (error) {
      throw this.handleError(error);
    }
  }

  async getTransactionsByAccount(accountNumber, skip = 0, limit = 100) {
    try {
      const response = await this.client.get(`/service/transaction/account/${accountNumber}`, {
        params: { skip, limit }
      });
      return response.data;
    } catch (error) {
      throw this.handleError(error);
    }
  }

  async getTransactionById(transactionId) {
    try {
      const response = await this.client.get(`/service/transaction/${transactionId}`);
      return response.data;
    } catch (error) {
      throw this.handleError(error);
    }
  }

  // ===== Error Handling =====

  handleError(error) {
    if (error.response) {
      // Service Layer returned an error
      const serviceError = new Error(error.response.data.detail || error.response.data.message || 'Service layer error');
      serviceError.status = error.response.status;
      serviceError.data = error.response.data;
      return serviceError;
    } else if (error.request) {
      // Service Layer tidak merespon
      const connectionError = new Error('Unable to connect to service layer. Please ensure service is running.');
      connectionError.status = 503;
      return connectionError;
    } else {
      // Error lainnya
      return error;
    }
  }
}

module.exports = new ServiceLayerClient();
