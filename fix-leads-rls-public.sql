-- Allow public access to all leads for testing purposes
-- This removes user-based restrictions and allows viewing all leads

-- Drop existing restrictive policies
DROP POLICY IF EXISTS "Users can view their own leads" ON public.leads;
DROP POLICY IF EXISTS "Anonymous users can view all leads" ON public.leads;

-- Create a simple policy that allows everyone to view all leads
CREATE POLICY "Allow public read access to all leads" 
    ON public.leads 
    FOR SELECT 
    USING (true);

-- Also allow authenticated users to manage leads
CREATE POLICY "Authenticated users can manage leads" 
    ON public.leads 
    FOR ALL
    USING (auth.role() = 'authenticated');

-- Grant permissions to anon role
GRANT SELECT ON public.leads TO anon;
GRANT ALL ON public.leads TO authenticated;
GRANT ALL ON public.leads TO service_role;

-- Verification query
SELECT 'Public access enabled for leads' as status, count(*) as policy_count 
FROM pg_policies WHERE tablename = 'leads';