-- Fix leads table RLS policies
-- This script creates RLS policies for the leads table so users can access their leads

-- Drop existing policies if they exist (just to be safe)
DROP POLICY IF EXISTS "Users can view their own leads" ON public.leads;
DROP POLICY IF EXISTS "Users can create their own leads" ON public.leads;
DROP POLICY IF EXISTS "Users can update their own leads" ON public.leads;
DROP POLICY IF EXISTS "Users can delete their own leads" ON public.leads;

-- Create RLS policies for leads
CREATE POLICY "Users can view their own leads" 
    ON public.leads 
    FOR SELECT 
    USING (user_id = auth.uid()::text);

CREATE POLICY "Users can create their own leads" 
    ON public.leads 
    FOR INSERT 
    WITH CHECK (user_id = auth.uid()::text);

CREATE POLICY "Users can update their own leads" 
    ON public.leads 
    FOR UPDATE 
    USING (user_id = auth.uid()::text);

CREATE POLICY "Users can delete their own leads" 
    ON public.leads 
    FOR DELETE 
    USING (user_id = auth.uid()::text);

-- Grant necessary permissions
GRANT ALL ON public.leads TO authenticated;
GRANT ALL ON public.leads TO service_role;

-- For now, also allow anonymous access for testing (you may want to remove this later)
CREATE POLICY "Anonymous users can view all leads" 
    ON public.leads 
    FOR SELECT 
    USING (true);

-- Verification query
SELECT 'leads RLS policies created' as status, count(*) as policy_count 
FROM pg_policies WHERE tablename = 'leads';