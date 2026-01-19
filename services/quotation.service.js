import { db } from '../config/firebase.js';
import logger from '../utils/logger.util.js';
import { FieldValue } from 'firebase-admin/firestore';

class QuotationService {
  constructor() {
    this.jobsCollection = db.collection('jobs');
    this.clientsCollection = db.collection('clients');
    this.workersCollection = db.collection('workers');
  }

  async submitQuotation(jobId, workerUid, quotationData) {
    const jobRef = this.jobsCollection.doc(jobId);
    const workerRef = this.workersCollection.doc(workerUid);
    
    try {
      // Run all reads before transaction
      const [jobDoc, workerDoc] = await Promise.all([
        jobRef.get(),
        workerRef.get()
      ]);

      // Validate job exists
      if (!jobDoc.exists) {
        throw new Error('Job not found');
      }

      const jobData = jobDoc.data();

      // Check if job is available for quotations
      if (jobData.status !== 'posted') {
        throw new Error('Job is not available for quotations');
      }

      // Validate worker exists
      if (!workerDoc.exists) {
        throw new Error('Worker profile not found. Please complete your profile first.');
      }

      // Check for duplicate quotation
      const quotationsRef = jobRef.collection('quotations');
      const existingQuotation = await quotationsRef
        .where('worker_uid', '==', workerUid)
        .get();

      if (!existingQuotation.empty) {
        throw new Error('You have already submitted a quotation for this job');
      }

      // Use transaction for atomic operations
      const result = await db.runTransaction(async (transaction) => {
        // Create quotation document reference
        const quotationRef = quotationsRef.doc();
        const quotationId = quotationRef.id;

        const quotation = {
          worker_uid: workerUid,
          estimated_cost: quotationData.estimated_cost.toString(),
          estimated_time: quotationData.estimated_time,
          description: quotationData.description || '',
          price_breakdown: quotationData.price_breakdown || null,
          notes: quotationData.notes || '',
          portfolio_photo_ids: quotationData.portfolio_photo_ids || [],
          availability: quotationData.availability || '',
          status: 'submitted',
          created_at: FieldValue.serverTimestamp(),
          viewed_by_client: false,
          viewed_at: null
        };

        // Set quotation
        transaction.set(quotationRef, quotation);

        // Update worker's jobs.applied array
        transaction.update(workerRef, {
          'jobs.applied': FieldValue.arrayUnion(jobRef)
        });

        return {
          quotationId,
          workerData: workerDoc.data()
        };
      });

      // Return response
      return {
        id: result.quotationId,
        jobId: jobId,
        workerId: workerUid,
        worker: {
          name: result.workerData.name,
          profile_img: result.workerData.profile_img,
          avg_rating: result.workerData.avg_rating || 0
        },
        estimated_cost: quotationData.estimated_cost,
        estimated_time: quotationData.estimated_time,
        description: quotationData.description || '',
        price_breakdown: quotationData.price_breakdown || null,
        notes: quotationData.notes || '',
        portfolio_photo_ids: quotationData.portfolio_photo_ids || [],
        availability: quotationData.availability || '',
        status: 'submitted',
        created_at: new Date().toISOString()
      };
    } catch (error) {
      logger.error('Error in submitQuotation service:', error);
      throw error;
    }
  }

  async getJobQuotations(jobId, userUid, options = {}) {
    try {
      const jobRef = this.jobsCollection.doc(jobId);
      const jobDoc = await jobRef.get();

      if (!jobDoc.exists) {
        throw new Error('Job not found');
      }

      const jobData = jobDoc.data();

      // Check authorization - only job owner can view quotations
      if (jobData.client_uid !== userUid) {
        throw new Error('Unauthorized to view quotations for this job');
      }

      // Get all quotations
      let quotationsQuery = jobRef.collection('quotations');

      // Apply sorting
      const sortBy = options.sortBy || 'created_at';
      const sortOrder = options.sortOrder || 'desc';
      quotationsQuery = quotationsQuery.orderBy(sortBy, sortOrder);

      const quotationsSnapshot = await quotationsQuery.get();
      const quotations = [];

      // Use batch for marking quotations as viewed
      const batch = db.batch();
      let batchCount = 0;

      for (const doc of quotationsSnapshot.docs) {
        const quotationData = doc.data();

        // Mark as viewed by client
        if (!quotationData.viewed_by_client) {
          batch.update(doc.ref, {
            viewed_by_client: true,
            viewed_at: FieldValue.serverTimestamp()
          });
          batchCount++;
        }

        // Get worker details
        let workerInfo = null;
        if (quotationData.worker_uid) {
          try {
            const workerDoc = await this.workersCollection.doc(quotationData.worker_uid).get();
            if (workerDoc.exists) {
              const worker = workerDoc.data();
              workerInfo = {
                id: quotationData.worker_uid,
                name: worker.name,
                photo: worker.profile_img,
                rating: worker.avg_rating || 0,
                reviewsCount: worker.reviews ? worker.reviews.length : 0,
                bio: worker.bio,
                skills: worker.skills || [],
                verified: true
              };
            }
          } catch (workerError) {
            logger.warn(`Failed to fetch worker ${quotationData.worker_uid}:`, workerError);
          }
        }

        const toISOString = (timestamp) => {
          if (!timestamp) return null;
          if (timestamp.toDate && typeof timestamp.toDate === 'function') {
            return timestamp.toDate().toISOString();
          }
          if (timestamp instanceof Date) {
            return timestamp.toISOString();
          }
          return timestamp;
        };

        quotations.push({
          id: doc.id,
          worker: workerInfo,
          estimated_cost: parseFloat(quotationData.estimated_cost),
          estimated_time: quotationData.estimated_time,
          description: quotationData.description,
          price_breakdown: quotationData.price_breakdown,
          notes: quotationData.notes,
          portfolio_photo_ids: quotationData.portfolio_photo_ids || [],
          availability: quotationData.availability,
          status: quotationData.status,
          created_at: toISOString(quotationData.created_at)
        });
      }

      // Commit batch updates if any
      if (batchCount > 0) {
        try {
          await batch.commit();
        } catch (batchError) {
          logger.error('Failed to update viewed status:', batchError);
          // Don't throw - this is a non-critical update
        }
      }

      return {
        jobId: jobId,
        quotations: quotations,
        count: quotations.length
      };
    } catch (error) {
      logger.error('Error in getJobQuotations service:', error);
      throw error;
    }
  }


  async getQuotationDetails(jobId, quotationId, userUid) {
    try {
      const jobRef = this.jobsCollection.doc(jobId);
      const jobDoc = await jobRef.get();

      if (!jobDoc.exists) {
        throw new Error('Job not found');
      }

      const jobData = jobDoc.data();

      const quotationRef = jobRef.collection('quotations').doc(quotationId);
      const quotationDoc = await quotationRef.get();

      if (!quotationDoc.exists) {
        return null;
      }

      const quotationData = quotationDoc.data();

      // Check authorization
      if (jobData.client_uid !== userUid && quotationData.worker_uid !== userUid) {
        throw new Error('Unauthorized to view this quotation');
      }

      // Get worker details
      let workerInfo = null;
      if (quotationData.worker_uid) {
        try {
          const workerDoc = await this.workersCollection.doc(quotationData.worker_uid).get();
          if (workerDoc.exists) {
            const worker = workerDoc.data();
            workerInfo = {
              id: quotationData.worker_uid,
              name: worker.name,
              photo: worker.profile_img,
              rating: worker.avg_rating || 0,
              reviewsCount: worker.reviews ? worker.reviews.length : 0,
              bio: worker.bio,
              skills: worker.skills || [],
              address: worker.address,
              verified: true
            };
          }
        } catch (workerError) {
          logger.warn(`Failed to fetch worker details:`, workerError);
        }
      }

      const toISOString = (timestamp) => {
        if (!timestamp) return null;
        if (timestamp.toDate && typeof timestamp.toDate === 'function') {
          return timestamp.toDate().toISOString();
        }
        if (timestamp instanceof Date) {
          return timestamp.toISOString();
        }
        return timestamp;
      };

      return {
        id: quotationId,
        jobId: jobId,
        job: {
          service_type: jobData.service_type,
          description: jobData.description,
          address: jobData.address
        },
        worker: workerInfo,
        estimated_cost: parseFloat(quotationData.estimated_cost),
        estimated_time: quotationData.estimated_time,
        description: quotationData.description,
        price_breakdown: quotationData.price_breakdown,
        notes: quotationData.notes,
        portfolio_photo_ids: quotationData.portfolio_photo_ids || [],
        availability: quotationData.availability,
        status: quotationData.status,
        created_at: toISOString(quotationData.created_at)
      };
    } catch (error) {
      logger.error('Error in getQuotationDetails service:', error);
      throw error;
    }
  }

  async updateQuotation(jobId, quotationId, workerUid, updateData) {
    const jobRef = this.jobsCollection.doc(jobId);
    const quotationRef = jobRef.collection('quotations').doc(quotationId);

    try {
      const quotationDoc = await quotationRef.get();

      if (!quotationDoc.exists) {
        throw new Error('Quotation not found');
      }

      const quotationData = quotationDoc.data();

      // Check authorization
      if (quotationData.worker_uid !== workerUid) {
        throw new Error('Unauthorized to update this quotation');
      }

      // Check if already accepted or rejected
      if (quotationData.status === 'accepted' || quotationData.status === 'rejected') {
        throw new Error('Cannot update accepted or rejected quotation');
      }

      // Check if viewed by client
      if (quotationData.viewed_by_client) {
        throw new Error('Cannot update quotation that has been viewed by client');
      }

      // Check 5-minute window
      const createdAt = quotationData.created_at.toDate();
      const now = new Date();
      const diffMinutes = (now - createdAt) / (1000 * 60);

      // TODO : change to 5
      // if (diffMinutes > 05) {
      //   throw new Error('Cannot update quotation after 5 minutes');
      // }

      // Allowed fields to update
      const allowedFields = ['estimated_cost', 'estimated_time', 'description', 'notes', 'price_breakdown'];
      const updates = {};

      Object.keys(updateData).forEach(key => {
        if (allowedFields.includes(key)) {
          if (key === 'estimated_cost') {
            updates[key] = updateData[key].toString();
          } else {
            updates[key] = updateData[key];
          }
        }
      });

      if (Object.keys(updates).length === 0) {
        throw new Error('No valid fields to update');
      }

      updates.updated_at = FieldValue.serverTimestamp();

      // Use transaction for atomic update
      await db.runTransaction(async (transaction) => {
        // Re-read to ensure data hasn't changed
        const freshQuotation = await transaction.get(quotationRef);
        
        if (!freshQuotation.exists) {
          throw new Error('Quotation not found');
        }

        const freshData = freshQuotation.data();
        
        // Re-validate conditions
        if (freshData.viewed_by_client) {
          throw new Error('Cannot update quotation that has been viewed by client');
        }

        if (freshData.status === 'accepted' || freshData.status === 'rejected') {
          throw new Error('Cannot update accepted or rejected quotation');
        }

        transaction.update(quotationRef, updates);
      });

      return await this.getQuotationDetails(jobId, quotationId, workerUid);
    } catch (error) {
      logger.error('Error in updateQuotation service:', error);
      throw error;
    }
  }

  async withdrawQuotation(jobId, quotationId, workerUid, reason) {
    const jobRef = this.jobsCollection.doc(jobId);
    const quotationRef = jobRef.collection('quotations').doc(quotationId);
    const workerRef = this.workersCollection.doc(workerUid);

    try {
      const quotationDoc = await quotationRef.get();

      if (!quotationDoc.exists) {
        throw new Error('Quotation not found');
      }

      const quotationData = quotationDoc.data();

      // Check authorization
      if (quotationData.worker_uid !== workerUid) {
        throw new Error('Unauthorized to withdraw this quotation');
      }

      // Cannot withdraw if accepted
      if (quotationData.status === 'accepted') {
        throw new Error('Cannot withdraw accepted quotation');
      }

      // Use transaction for atomic operations
      await db.runTransaction(async (transaction) => {
        // Re-read to ensure status hasn't changed
        const freshQuotation = await transaction.get(quotationRef);
        
        if (!freshQuotation.exists) {
          throw new Error('Quotation not found');
        }

        if (freshQuotation.data().status === 'accepted') {
          throw new Error('Cannot withdraw accepted quotation');
        }

        // Update quotation status
        transaction.update(quotationRef, {
          status: 'withdrawn',
          withdrawn_at: FieldValue.serverTimestamp(),
          withdrawal_reason: reason || ''
        });

        // Update worker's job arrays
        transaction.update(workerRef, {
          'jobs.applied': FieldValue.arrayRemove(jobRef),
          'jobs.declined': FieldValue.arrayUnion(jobRef)
        });
      });

      return {
        id: quotationId,
        status: 'withdrawn',
        withdrawn_at: new Date().toISOString()
      };
    } catch (error) {
      logger.error('Error in withdrawQuotation service:', error);
      throw error;
    }
  }

  async acceptQuotation(jobId, quotationId, clientUid, scheduleData) {
    const jobRef = this.jobsCollection.doc(jobId);
    const quotationRef = jobRef.collection('quotations').doc(quotationId);

    try {
      // Read all necessary data first
      const [jobDoc, quotationDoc] = await Promise.all([
        jobRef.get(),
        quotationRef.get()
      ]);

      if (!jobDoc.exists) {
        throw new Error('Job not found');
      }

      const jobData = jobDoc.data();

      // Check authorization
      if (jobData.client_uid !== clientUid) {
        throw new Error('Unauthorized to accept this quotation');
      }

      if (!quotationDoc.exists) {
        throw new Error('Quotation not found');
      }

      const quotationData = quotationDoc.data();

      // Check quotation status
      if (quotationData.status === 'withdrawn') {
        throw new Error('Quotation has been withdrawn by worker');
      }

      if (quotationData.status === 'accepted' || quotationData.status === 'rejected') {
        throw new Error('Quotation already accepted or rejected');
      }

      const workerUid = quotationData.worker_uid;
      const clientRef = this.clientsCollection.doc(clientUid);
      const workerRef = this.workersCollection.doc(workerUid);

      // Prepare scheduled time
      let scheduledAt = null;
      if (scheduleData.scheduled_at) {
        scheduledAt = typeof scheduleData.scheduled_at === 'string' 
          ? new Date(scheduleData.scheduled_at) 
          : scheduleData.scheduled_at;
      }

      // Get all quotations to reject
      const allQuotationsSnapshot = await jobRef.collection('quotations').get();

      // Use transaction for all updates
      await db.runTransaction(async (transaction) => {
        // Re-read to ensure nothing has changed
        const freshQuotation = await transaction.get(quotationRef);
        
        if (!freshQuotation.exists) {
          throw new Error('Quotation not found');
        }

        const freshQuotationData = freshQuotation.data();

        if (freshQuotationData.status !== 'submitted') {
          throw new Error('Quotation status has changed');
        }

        // Update accepted quotation
        transaction.update(quotationRef, {
          status: 'accepted',
          accepted_at: FieldValue.serverTimestamp()
        });

        // Update job
        transaction.update(jobRef, {
          finalized_quotation: quotationRef,
          status: 'confirmed',
          scheduled_at: scheduledAt,
          client_notes: scheduleData.notes || ''
        });

        // Reject all other submitted quotations
        allQuotationsSnapshot.docs.forEach(doc => {
          if (doc.id !== quotationId && doc.data().status === 'submitted') {
            transaction.update(doc.ref, {
              status: 'rejected',
              rejected_at: FieldValue.serverTimestamp(),
              auto_rejected: true
            });
          }
        });

        // Update client services
        transaction.update(clientRef, {
          'services.requested': FieldValue.arrayRemove(jobRef),
          'services.scheduled': FieldValue.arrayUnion(jobRef)
        });

        // Update worker jobs
        transaction.update(workerRef, {
          'jobs.applied': FieldValue.arrayRemove(jobRef),
          'jobs.confirmed': FieldValue.arrayUnion(jobRef)
        });
      });

      return {
        quotationId: quotationId,
        jobId: jobId,
        status: 'accepted',
        scheduled_at: scheduledAt ? scheduledAt.toISOString() : null,
        message: 'Quotation accepted and job scheduled successfully'
      };
    } catch (error) {
      logger.error('Error in acceptQuotation service:', error);
      throw error;
    }
  }

  async rejectQuotation(jobId, quotationId, clientUid, reason) {
    const jobRef = this.jobsCollection.doc(jobId);
    const quotationRef = jobRef.collection('quotations').doc(quotationId);

    try {
      const [jobDoc, quotationDoc] = await Promise.all([
        jobRef.get(),
        quotationRef.get()
      ]);

      if (!jobDoc.exists) {
        throw new Error('Job not found');
      }

      const jobData = jobDoc.data();

      // Check authorization
      if (jobData.client_uid !== clientUid) {
        throw new Error('Unauthorized to reject this quotation');
      }

      if (!quotationDoc.exists) {
        throw new Error('Quotation not found');
      }

      const quotationData = quotationDoc.data();

      if (quotationData.status === 'accepted' || quotationData.status === 'rejected') {
        throw new Error('Quotation already accepted or rejected');
      }

      // Use transaction for atomic update
      await db.runTransaction(async (transaction) => {
        const freshQuotation = await transaction.get(quotationRef);
        
        if (!freshQuotation.exists) {
          throw new Error('Quotation not found');
        }

        const freshData = freshQuotation.data();

        if (freshData.status === 'accepted' || freshData.status === 'rejected') {
          throw new Error('Quotation already accepted or rejected');
        }

        transaction.update(quotationRef, {
          status: 'rejected',
          rejected_at: FieldValue.serverTimestamp(),
          rejection_reason: reason || ''
        });
      });

      return {
        id: quotationId,
        status: 'rejected',
        rejected_at: new Date().toISOString()
      };
    } catch (error) {
      logger.error('Error in rejectQuotation service:', error);
      throw error;
    }
  }

  async getWorkerQuotations(workerUid, options = {}) {
    try {
      const { status, page = 1, limit = 20, sortBy = 'created_at', sortOrder = 'desc' } = options;

      // Get all jobs where worker has applied
      const jobsSnapshot = await this.jobsCollection.get();
      const quotations = [];

      const quotationPromises = jobsSnapshot.docs.map(async (jobDoc) => {
        try {
          const quotationsRef = jobDoc.ref.collection('quotations');
          let query = quotationsRef.where('worker_uid', '==', workerUid);

          if (status) {
            query = query.where('status', '==', status);
          }

          const quotationsSnapshot = await query.get();

          return quotationsSnapshot.docs.map(quotationDoc => {
            const quotationData = quotationDoc.data();
            const jobData = jobDoc.data();

            const toISOString = (timestamp) => {
              if (!timestamp) return null;
              if (timestamp.toDate && typeof timestamp.toDate === 'function') {
                return timestamp.toDate().toISOString();
              }
              if (timestamp instanceof Date) {
                return timestamp.toISOString();
              }
              return timestamp;
            };

            return {
              id: quotationDoc.id,
              job: {
                id: jobDoc.id,
                service_type: jobData.service_type,
                description: jobData.description,
                address: jobData.address,
                status: jobData.status
              },
              estimated_cost: parseFloat(quotationData.estimated_cost),
              estimated_time: quotationData.estimated_time,
              status: quotationData.status,
              created_at: toISOString(quotationData.created_at),
              accepted_at: toISOString(quotationData.accepted_at),
              rejected_at: toISOString(quotationData.rejected_at),
              withdrawn_at: toISOString(quotationData.withdrawn_at)
            };
          });
        } catch (error) {
          logger.warn(`Failed to fetch quotations for job ${jobDoc.id}:`, error);
          return [];
        }
      });

      const quotationArrays = await Promise.all(quotationPromises);
      quotationArrays.forEach(arr => quotations.push(...arr));

      // Sort quotations
      quotations.sort((a, b) => {
        const aValue = a[sortBy];
        const bValue = b[sortBy];
        
        if (sortOrder === 'asc') {
          return aValue > bValue ? 1 : -1;
        } else {
          return aValue < bValue ? 1 : -1;
        }
      });

      // Pagination
      const startIndex = (page - 1) * limit;
      const endIndex = startIndex + limit;
      const paginatedQuotations = quotations.slice(startIndex, endIndex);

      return {
        items: paginatedQuotations,
        pagination: {
          page: page,
          limit: limit,
          total: quotations.length,
          totalPages: Math.ceil(quotations.length / limit)
        }
      };
    } catch (error) {
      logger.error('Error in getWorkerQuotations service:', error);
      throw error;
    }
  }
}

export default new QuotationService();