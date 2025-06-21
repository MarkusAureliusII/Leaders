-- Fix Missing scrape_jobs Table and Relationship
-- This script creates the missing scrape_jobs table and establishes proper relationships

-- 1. Create the scrape_jobs table
CREATE TABLE IF NOT EXISTS public.scrape_jobs (
    id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    job_name TEXT,
    apify_run_id TEXT,
    started_at TIMESTAMP WITH TIME ZONE,
    finished_at TIMESTAMP WITH TIME ZONE,
    lead_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- 2. Add foreign key constraint from leads to scrape_jobs (if not exists)
-- First check if the constraint already exists and add if missing
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'leads_scrape_job_id_fkey'
        AND table_name = 'leads'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.leads 
        ADD CONSTRAINT leads_scrape_job_id_fkey 
        FOREIGN KEY (scrape_job_id) REFERENCES public.scrape_jobs(id) ON DELETE SET NULL;
    END IF;
END $$;

-- 3. Enable Row Level Security
ALTER TABLE public.scrape_jobs ENABLE ROW LEVEL SECURITY;

-- 4. Create RLS policies for scrape_jobs
-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own scrape jobs" ON public.scrape_jobs;
DROP POLICY IF EXISTS "Users can create their own scrape jobs" ON public.scrape_jobs;
DROP POLICY IF EXISTS "Users can update their own scrape jobs" ON public.scrape_jobs;
DROP POLICY IF EXISTS "Users can delete their own scrape jobs" ON public.scrape_jobs;

-- Create new policies
CREATE POLICY "Users can view their own scrape jobs" 
    ON public.scrape_jobs 
    FOR SELECT 
    USING (user_id = auth.uid());

CREATE POLICY "Users can create their own scrape jobs" 
    ON public.scrape_jobs 
    FOR INSERT 
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own scrape jobs" 
    ON public.scrape_jobs 
    FOR UPDATE 
    USING (user_id = auth.uid());

CREATE POLICY "Users can delete their own scrape jobs" 
    ON public.scrape_jobs 
    FOR DELETE 
    USING (user_id = auth.uid());

-- 5. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_scrape_jobs_user_id ON public.scrape_jobs(user_id);
CREATE INDEX IF NOT EXISTS idx_scrape_jobs_started_at ON public.scrape_jobs(started_at);
CREATE INDEX IF NOT EXISTS idx_scrape_jobs_apify_run_id ON public.scrape_jobs(apify_run_id);

-- 6. Create index on leads.scrape_job_id for foreign key performance
CREATE INDEX IF NOT EXISTS idx_leads_scrape_job_id ON public.leads(scrape_job_id);

-- 7. Create a trigger to automatically update the updated_at column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_scrape_jobs_updated_at 
    BEFORE UPDATE ON public.scrape_jobs 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- 8. Grant necessary permissions
GRANT ALL ON public.scrape_jobs TO authenticated;
GRANT ALL ON public.scrape_jobs TO service_role;

-- 9. Insert a sample scrape job for testing (optional)
-- This helps verify the relationship works and provides demo data
INSERT INTO public.scrape_jobs (
    id,
    user_id,
    job_name,
    apify_run_id,
    started_at,
    finished_at,
    lead_count
) 
SELECT 
    gen_random_uuid(),
    u.id,
    'Sample Scrape Job',
    'sample_run_123',
    now() - interval '1 hour',
    now() - interval '30 minutes',
    (SELECT COUNT(*) FROM public.leads WHERE user_id = u.id)
FROM auth.users u
WHERE EXISTS (SELECT 1 FROM public.leads WHERE user_id = u.id)
ON CONFLICT DO NOTHING;

-- 10. Update existing leads to link them to the sample scrape job (if any exist without scrape_job_id)
UPDATE public.leads 
SET scrape_job_id = (
    SELECT id FROM public.scrape_jobs 
    WHERE user_id = leads.user_id 
    LIMIT 1
)
WHERE scrape_job_id IS NULL 
AND user_id IS NOT NULL;

-- Verification queries (for testing)
-- SELECT 'scrape_jobs table created' as status, count(*) as record_count FROM public.scrape_jobs;
-- SELECT 'leads with scrape_job_id' as status, count(*) as record_count FROM public.leads WHERE scrape_job_id IS NOT NULL;
-- SELECT 'Foreign key constraint exists' as status, count(*) as constraint_count 
-- FROM information_schema.table_constraints 
-- WHERE constraint_name = 'leads_scrape_job_id_fkey';