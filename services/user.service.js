import { db } from '../config/firebase.js';
import logger from '../utils/logger.util.js';

class UserService {
  constructor() {
    this.clientsCollection = db.collection('clients');
    this.workersCollection = db.collection('workers');
    this.jobsCollection = db.collection('jobs');
  }

  async getUserProfile(uid) {
    try {
      const clientDoc = await this.clientsCollection.doc(uid).get();
      
      if (clientDoc.exists) {
        const data = clientDoc.data();
        return {
          id: uid,
          role: 'client',
          name: data.name,
          email: data.email,
          phone: data.phone,
          addresses: data.addresses || [],
          services: data.services || {
            requested: [],
            scheduled: [],
            completed: [],
            cancelled: []
          },
          fcmToken: data.fcm_token,
          stats: await this.calculateClientStats(uid, data)
        };
      }

      const workerDoc = await this.workersCollection.doc(uid).get();
      
      if (workerDoc.exists) {
        const data = workerDoc.data();
        return {
          id: uid,
          role: 'worker',
          name: data.name,
          email: data.email,
          phone: data.phone,
          bio: data.bio,
          profileImg: data.profile_img,
          avgRating: data.avg_rating || 0,
          reviews: data.reviews || [],
          skills: data.skills || [],
          address: data.address,
          jobs: data.jobs || {
            applied: [],
            confirmed: [],
            completed: [],
            declined: []
          },
          fcmToken: data.fcm_token
        };
      }

      return null;
    } catch (error) {
      logger.error('Error fetching user profile:', error);
      throw error;
    }
  }

  async calculateClientStats(uid, clientData) {
    try {
      const services = clientData.services || {};

      const jobsPosted = (services.requested?.length || 0) + 
                        (services.scheduled?.length || 0) + 
                        (services.completed?.length || 0) + 
                        (services.cancelled?.length || 0);
      
      const jobsCompleted = services.completed?.length || 0;

      let totalSpent = 0;
      let totalRating = 0;
      let ratingCount = 0;

      if (services.completed && services.completed.length > 0) {
        for (const jobRef of services.completed) {
          const jobDoc = await jobRef.get();
          if (jobDoc.exists) {
            const jobData = jobDoc.data();
            
            if (jobData.finalized_quotation) {
              const quoDoc = await jobData.finalized_quotation.get();
              if (quoDoc.exists) {
                const quoData = quoDoc.data();
                totalSpent += parseFloat(quoData.estimated_cost) || 0;
              }
            }
          }
        }
      }

      const averageRating = ratingCount > 0 ? totalRating / ratingCount : 0;

      return {
        jobsPosted,
        jobsCompleted,
        averageRating: parseFloat(averageRating.toFixed(1)),
        totalSpent: parseFloat(totalSpent.toFixed(2))
      };
    } catch (error) {
      logger.error('Error calculating client stats:', error);
      return {
        jobsPosted: 0,
        jobsCompleted: 0,
        averageRating: 0,
        totalSpent: 0
      };
    }
  }

  async createClient(uid, clientData) {
    try {
      const client = {
        name: clientData.name,
        email: clientData.email,
        phone: clientData.phone,
        addresses: clientData.addresses || [],
        services: {
          requested: [],
          scheduled: [],
          completed: [],
          cancelled: []
        },
        fcm_token: clientData.fcmToken || ''
      };

      await this.clientsCollection.doc(uid).set(client);
      return { id: uid, ...client };
    } catch (error) {
      logger.error('Error creating client:', error);
      throw error;
    }
  }

  async updateUserProfile(uid, updateData) {
    try {
      const clientDoc = await this.clientsCollection.doc(uid).get();
      
      if (clientDoc.exists) {
        await this.clientsCollection.doc(uid).update(updateData);
        return await this.getUserProfile(uid);
      }

      const workerDoc = await this.workersCollection.doc(uid).get();
      
      if (workerDoc.exists) {
        await this.workersCollection.doc(uid).update(updateData);
        return await this.getUserProfile(uid);
      }

      return null;
    } catch (error) {
      logger.error('Error updating user profile:', error);
      throw error;
    }
  }
}

export default new UserService();