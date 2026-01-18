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

      // Parse scheduled_at if it's a string
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

      await jobRef.set(job);

      // Add job reference to client's requested array
      await this.clientsCollection.doc(clientUid).update({
        'services.requested': FieldValue.arrayUnion(jobRef)
      });

      // Return job with proper timestamp format
      return { 
        id: jobId, 
        ...job,
        created_at: new Date().toISOString(),
        scheduled_at: scheduledAt ? scheduledAt.toISOString() : null
      };
    } catch (error) {
      logger.error('Error creating job:', error);
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

      // Get client details
      let clientData = null;
      if (jobData.client_uid) {
        const clientDoc = await this.clientsCollection.doc(jobData.client_uid).get();
        if (clientDoc.exists) {
          const client = clientDoc.data();
          clientData = {
            name: client.name,
            phone: client.phone
          };
        }
      }

      // Get quotations count
      const quotationsSnapshot = await jobDoc.ref.collection('quotations').get();
      const quotationsCount = quotationsSnapshot.size;

      // Helper function to safely convert timestamp
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
      logger.error('Error fetching job:', error);
      throw error;
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

      // Helper function to safely convert timestamp
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

      // Helper function to safely convert timestamp
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
        
        // Get client info
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

      // Verify ownership
      if (jobData.client_uid !== clientUid) {
        throw new Error('Unauthorized to update this job');
      }

      // Cannot update if job is already confirmed
      if (jobData.status === 'confirmed' || jobData.status === 'completed') {
        throw new Error('Cannot update job in current status');
      }

      const allowedFields = ['service_type', 'description', 'address', 'scheduled_at'];
      const updates = {};

      Object.keys(updateData).forEach(key => {
        if (allowedFields.includes(key)) {
          updates[key] = updateData[key];
        }
      });

      await this.jobsCollection.doc(jobId).update(updates);

      return await this.getJobById(jobId);
    } catch (error) {
      logger.error('Error updating job:', error);
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

      // Verify ownership
      if (jobData.client_uid !== clientUid) {
        throw new Error('Unauthorized to cancel this job');
      }

      // Cannot cancel if already completed
      if (jobData.status === 'completed') {
        throw new Error('Cannot cancel completed job');
      }

      // Update job status
      await this.jobsCollection.doc(jobId).update({
        status: 'cancelled'
      });

      // Get job reference
      const jobRef = this.jobsCollection.doc(jobId);

      // Move from requested/scheduled to cancelled in client's services
      const clientDoc = await this.clientsCollection.doc(clientUid).get();
      const clientData = clientDoc.data();

      await this.clientsCollection.doc(clientUid).update({
        'services.requested': FieldValue.arrayRemove(jobRef),
        'services.scheduled': FieldValue.arrayRemove(jobRef),
        'services.cancelled': FieldValue.arrayUnion(jobRef)
      });

      return {
        id: jobId,
        status: 'cancelled'
      };
    } catch (error) {
      logger.error('Error cancelling job:', error);
      throw error;
    }
  }

  //TODO: In Delete Job dont delete job permanently, just mark status as deleted.
  async deleteJob(jobId, clientUid) {
    try {
      const jobDoc = await this.jobsCollection.doc(jobId).get();

      if (!jobDoc.exists) {
        return null;
      }

      const jobData = jobDoc.data();

      // Verify ownership
      if (jobData.client_uid !== clientUid) {
        throw new Error('Unauthorized to delete this job');
      }

      // Can only delete if posted or cancelled
      if (jobData.status !== 'posted' && jobData.status !== 'cancelled') {
        throw new Error('Cannot delete job in current status');
      }

      const jobRef = this.jobsCollection.doc(jobId);

      // Remove from client's services arrays
      await this.clientsCollection.doc(clientUid).update({
        'services.requested': FieldValue.arrayRemove(jobRef),
        'services.cancelled': FieldValue.arrayRemove(jobRef)
      });

      // Delete all quotations
      const quotationsSnapshot = await jobDoc.ref.collection('quotations').get();
      const batch = db.batch();
      quotationsSnapshot.docs.forEach(doc => {
        batch.delete(doc.ref);
      });
      await batch.commit();

      // Delete the job
      await this.jobsCollection.doc(jobId).delete();

      return true;
    } catch (error) {
      logger.error('Error deleting job:', error);
      throw error;
    }
  }
}

export default new JobService();