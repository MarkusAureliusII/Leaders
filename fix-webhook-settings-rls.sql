-- Fix webhook_settings RLS policies
-- This script creates RLS policies for the webhook_settings table so users can access their webhook configurations

-- Drop existing policies if they exist (just to be safe)
DROP POLICY IF EXISTS "Users can view their own webhook settings" ON public.webhook_settings;
DROP POLICY IF EXISTS "Users can create their own webhook settings" ON public.webhook_settings;
DROP POLICY IF EXISTS "Users can update their own webhook settings" ON public.webhook_settings;
DROP POLICY IF EXISTS "Users can delete their own webhook settings" ON public.webhook_settings;

-- Create RLS policies for webhook_settings
CREATE POLICY "Users can view their own webhook settings" 
    ON public.webhook_settings 
    FOR SELECT 
    USING (user_id = auth.uid()::text);

CREATE POLICY "Users can create their own webhook settings" 
    ON public.webhook_settings 
    FOR INSERT 
    WITH CHECK (user_id = auth.uid()::text);

CREATE POLICY "Users can update their own webhook settings" 
    ON public.webhook_settings 
    FOR UPDATE 
    USING (user_id = auth.uid()::text);

CREATE POLICY "Users can delete their own webhook settings" 
    ON public.webhook_settings 
    FOR DELETE 
    USING (user_id = auth.uid()::text);

-- Grant necessary permissions
GRANT ALL ON public.webhook_settings TO authenticated;
GRANT ALL ON public.webhook_settings TO service_role;

-- Verification query
SELECT 'webhook_settings RLS policies created' as status, count(*) as policy_count 
FROM pg_policies WHERE tablename = 'webhook_settings';