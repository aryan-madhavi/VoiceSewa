
# VoiceSewa 

Multilingual Voice-Assisted Job Connection Platform for Blue-Collar Services

## API Documentation


**[VoiceSewa API Documentation](https://docs.google.com/document/d/1rFZrZsstU4p5H9iGZwPMKSOur0DzXBaIUGbHPFCjgMI/edit?usp=sharing)**

## Database Schema

```bash
/// Firestore Database Schema
(default)

clients - collection
  client_uid - document
     {
      name: string,
      email: string,
      phone: string,
      addresses: [
        {
          location: geopoint,
          line1: string,
          line2: string,
          landmark: string,
          pincode: string,
          city: string
        }
      ],
      services: {
        requested: [reference<job-uuid>],
        scheduled: [reference<job-uuid>],
        completed: [reference<job-uuid>],
        cancelled: [reference<job-uuid>]
      },
      fcm_token: string
     }

workers - collection
  worker_uid - document
    {
      name: string,
      email: string,
      phone: string,
      bio: string,
      profile_img: link,
      avg_rating: number,
      reviews: [
        {
          rating: number,
          review: string
        }
      ]
      skills: [string],
      address: {
        location: geopoint,
        line1: string,
        line2: string,
        landmark: string,
        pincode: string,
        city: string
      },
      jobs: {
        applied: [reference<job-uuid>],
        confirmed: [reference<job-uuid>],
        completed: [reference<job-uuid>],
        declined: [reference<job-uuid>]
      },
      fcm_token: string
    }

jobs - collection
  job-uuid - document
    {
      service_type: string,
      description: string,
      address: {
        location: geopoint,
        line1: string,
        line2: string,
        landmark: string,
        pincode: string,
        city: string
      },
      client_uid: string,
      created_at: timestamp,
      status: string,
      finalized_quotation: reference<quo-uuid>,
      scheduled_at: timestamp,
    }
    quotations - collection
      quo-uuid - document
      {
        worker_uid: string,
        estimated_cost: string,
        estimated_time: string,
        description: string,
        price_breakdown: object | null,
        notes: string,
        portfolio_photo_ids: array,
        availability: string,
        status: "submitted" | "accepted" | "rejected" | "withdrawn",
        created_at: timestamp,
        updated_at: timestamp | null,
        viewed_by_client: boolean,
        viewed_at: timestamp | null,
        accepted_at: timestamp | null,
        rejected_at: timestamp | null,
        withdrawn_at: timestamp | null,
        rejection_reason: string | null,
        withdrawal_reason: string | null,
        auto_rejected: boolean | null
      }
```