import { db } from '../config/firebase.js';
import logger from '../utils/logger.util.js';
import { FieldValue } from 'firebase-admin/firestore';

class JobService {
  constructor() {
    this.jobsCollection = db.collection('jobs');
    this.clientsCollection = db.collection('clients');
    this.workersCollection = db.collection('workers');
  }

  async createJob(clientUid, jobData) {
    try {
      const jobRef = this.jobsCollection.doc();
      const jobId = jobRef.id;

      let scheduledAt = null;
      if (jobData.scheduled_at) {
        if (typeof jobData.scheduled_at === 'string') {
          scheduledAt = new Date(jobData.scheduled_at);
        } else {
          scheduledAt = jobData.scheduled_at;
        }
      }

      const job = {
        service_type: jobData.service_type,
        description: jobData.description,
        address: jobData.address,
        client_uid: clientUid,
        created_at: FieldValue.serverTimestamp(),
        status: 'posted',
        finalized_quotation: null,
        scheduled_at: scheduledAt
      };

      try {
        await jobRef.set(job);
      } catch (error) {
        logger.error('Failed to create job in Firestore:', error);
        throw new Error('Failed to create job. Please try again.');
      }

      try {
        await this.clientsCollection.doc(clientUid).update({
          'services.requested': FieldValue.arrayUnion(jobRef)
        });
      } catch (error) {
        logger.error('Failed to update client services, rolling back job creation:', error);
        try {
          await jobRef.delete();
        } catch (rollbackError) {
          logger.error('Rollback failed:', rollbackError);
        }
        throw new Error('Failed to update client profile. Job creation aborted.');
      }

      return { 
        id: jobId, 
        ...job,
        created_at: new Date().toISOString(),
        scheduled_at: scheduledAt ? scheduledAt.toISOString() : null
      };
    } catch (error) {
      logger.error('Error in createJob service:', error);
      throw error;
    }
  }

  async getJobById(jobId) {
    try {
      const jobDoc = await this.jobsCollection.doc(jobId).get();

      if (!jobDoc.exists) {
        return null;
      }

      const jobData = jobDoc.data();

      let clientData = null;
      if (jobData.client_uid) {
        try {
          const clientDoc = await this.clientsCollection.doc(jobData.client_uid).get();
          if (clientDoc.exists) {
            const client = clientDoc.data();
            clientData = {
              name: client.name,
              phone: client.phone
            };
          }
        } catch (error) {
          logger.error('Failed to fetch client details:', error);
        }
      }

      let quotationsCount = 0;
      try {
        const quotationsSnapshot = await jobDoc.ref.collection('quotations').get();
        quotationsCount = quotationsSnapshot.size;
      } catch (error) {
        logger.error('Failed to fetch quotations count:', error);
      }

      const toISOString = (timestamp) => {
        if (!timestamp) return null;
        if (timestamp.toDate && typeof timestamp.toDate === 'function') {
          return timestamp.toDate().toISOString();
        }
        if (timestamp instanceof Date) {
          return timestamp.toISOString();
        }
        if (typeof timestamp === 'string') {
          return timestamp;
        }
        return null;
      };

      return {
        id: jobId,
        ...jobData,
        client: clientData,
        quotationsCount,
        created_at: toISOString(jobData.created_at),
        scheduled_at: toISOString(jobData.scheduled_at)
      };
    } catch (error) {
      logger.error('Error in getJobById service:', error);
      throw new Error('Failed to retrieve job. Please try again.');
    }
  }

  async getClientJobs(clientUid, filters = {}) {
    try {
      let query = this.jobsCollection.where('client_uid', '==', clientUid);

      if (filters.status) {
        query = query.where('status', '==', filters.status);
      }

      query = query.orderBy('created_at', 'desc');

      const snapshot = await query.get();
      const jobs = [];

      const toISOString = (timestamp) => {
        if (!timestamp) return null;
        if (timestamp.toDate && typeof timestamp.toDate === 'function') {
          return timestamp.toDate().toISOString();
        }
        if (timestamp instanceof Date) {
          return timestamp.toISOString();
        }
        if (typeof timestamp === 'string') {
          return timestamp;
        }
        return null;
      };

      for (const doc of snapshot.docs) {
        const jobData = doc.data();
        const quotationsSnapshot = await doc.ref.collection('quotations').get();

        jobs.push({
          id: doc.id,
          service_type: jobData.service_type,
          description: jobData.description,
          status: jobData.status,
          address: jobData.address,
          quotationsCount: quotationsSnapshot.size,
          created_at: toISOString(jobData.created_at),
          scheduled_at: toISOString(jobData.scheduled_at)
        });
      }

      return jobs;
    } catch (error) {
      logger.error('Error fetching client jobs:', error);
      throw error;
    }
  }

  async getAvailableJobs(workerUid, filters = {}) {
    try {
      let query = this.jobsCollection.where('status', '==', 'posted');

      const snapshot = await query.get();
      const jobs = [];

      const toISOString = (timestamp) => {
        if (!timestamp) return null;
        if (timestamp.toDate && typeof timestamp.toDate === 'function') {
          return timestamp.toDate().toISOString();
        }
        if (timestamp instanceof Date) {
          return timestamp.toISOString();
        }
        if (typeof timestamp === 'string') {
          return timestamp;
        }
        return null;
      };

      for (const doc of snapshot.docs) {
        const jobData = doc.data();
        
        let clientInfo = null;
        if (jobData.client_uid) {
          const clientDoc = await this.clientsCollection.doc(jobData.client_uid).get();
          if (clientDoc.exists) {
            const clientData = clientDoc.data();
            clientInfo = {
              name: clientData.name
            };
          }
        }

        const quotationsSnapshot = await doc.ref.collection('quotations').get();

        jobs.push({
          id: doc.id,
          service_type: jobData.service_type,
          description: jobData.description,
          address: jobData.address,
          client: clientInfo,
          quotationsCount: quotationsSnapshot.size,
          created_at: toISOString(jobData.created_at)
        });
      }

      return jobs;
    } catch (error) {
      logger.error('Error fetching available jobs:', error);
      throw error;
    }
  }

  async updateJob(jobId, clientUid, updateData) {
    try {
      const jobDoc = await this.jobsCollection.doc(jobId).get();

      if (!jobDoc.exists) {
        return null;
      }

      const jobData = jobDoc.data();

      if (jobData.client_uid !== clientUid) {
        throw new Error('Unauthorized to update this job');
      }

      if (jobData.status === 'confirmed' || jobData.status === 'completed') {
        throw new Error('Cannot update job in current status');
      }

      const allowedFields = ['service_type', 'description', 'address', 'scheduled_at'];
      const updates = {};

      Object.keys(updateData).forEach(key => {
        if (allowedFields.includes(key)) {
          if (key === 'scheduled_at' && typeof updateData[key] === 'string') {
            updates[key] = new Date(updateData[key]);
          } else {
            updates[key] = updateData[key];
          }
        }
      });

      if (Object.keys(updates).length === 0) {
        throw new Error('No valid fields to update');
      }

      try {
        await this.jobsCollection.doc(jobId).update(updates);
      } catch (error) {
        logger.error('Failed to update job in Firestore:', error);
        throw new Error('Failed to update job. Please try again.');
      }

      return await this.getJobById(jobId);
    } catch (error) {
      logger.error('Error in updateJob service:', error);
      throw error;
    }
  }

  async cancelJob(jobId, clientUid) {
    try {
      const jobDoc = await this.jobsCollection.doc(jobId).get();

      if (!jobDoc.exists) {
        return null;
      }

      const jobData = jobDoc.data();

      if (jobData.client_uid !== clientUid) {
        throw new Error('Unauthorized to cancel this job');
      }

      if (jobData.status === 'completed') {
        throw new Error('Cannot cancel completed job');
      }

      try {
        await this.jobsCollection.doc(jobId).update({
          status: 'cancelled'
        });
      } catch (error) {
        logger.error('Failed to update job status to cancelled:', error);
        throw new Error('Failed to cancel job. Please try again.');
      }

      const jobRef = this.jobsCollection.doc(jobId);

      try {
        await this.clientsCollection.doc(clientUid).update({
          'services.requested': FieldValue.arrayRemove(jobRef),
          'services.scheduled': FieldValue.arrayRemove(jobRef),
          'services.cancelled': FieldValue.arrayUnion(jobRef)
        });
      } catch (error) {
        logger.error('Failed to update client services, rolling back cancellation:', error);
        try {
          await this.jobsCollection.doc(jobId).update({
            status: jobData.status 
          });
        } catch (rollbackError) {
          logger.error('Rollback failed:', rollbackError);
        }
        throw new Error('Failed to update client profile. Cancellation aborted.');
      }

      return {
        id: jobId,
        status: 'cancelled'
      };
    } catch (error) {
      logger.error('Error in cancelJob service:', error);
      throw error;
    }
  }

  async deleteJob(jobId, clientUid) {
    try {
      const jobDoc = await this.jobsCollection.doc(jobId).get();

      if (!jobDoc.exists) {
        return null;
      }

      const jobData = jobDoc.data();

      if (jobData.client_uid !== clientUid) {
        throw new Error('Unauthorized to delete this job');
      }

      if (jobData.status !== 'posted' && jobData.status !== 'cancelled') {
        throw new Error('Cannot delete job in current status');
      }

      const jobRef = this.jobsCollection.doc(jobId);

      await this.clientsCollection.doc(clientUid).update({
        'services.requested': FieldValue.arrayRemove(jobRef),
        'services.cancelled': FieldValue.arrayRemove(jobRef)
      });

      const quotationsSnapshot = await jobDoc.ref.collection('quotations').get();
      const batch = db.batch();
      quotationsSnapshot.docs.forEach(doc => {
        batch.delete(doc.ref);
      });
      await batch.commit();

      await this.jobsCollection.doc(jobId).delete();

      return true;
    } catch (error) {
      logger.error('Error deleting job:', error);
      throw error;
    }
  }
}

export default new JobService();