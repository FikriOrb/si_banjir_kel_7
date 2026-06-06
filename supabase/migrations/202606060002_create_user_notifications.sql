CREATE TYPE public.notification_type AS ENUM ('comment_on_report', 'reply_to_comment');

CREATE TABLE public.user_notifications (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  actor_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  type public.notification_type NOT NULL,
  report_id uuid NOT NULL REFERENCES public.flood_reports(id) ON DELETE CASCADE,
  comment_id uuid NOT NULL REFERENCES public.report_comments(id) ON DELETE CASCADE,
  is_read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.user_notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users can read own notifications"
ON public.user_notifications FOR SELECT
TO authenticated
USING (user_id = auth.uid());

CREATE POLICY "users can update own notifications"
ON public.user_notifications FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users can delete own notifications"
ON public.user_notifications FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- Trigger function to create notification on new comment
CREATE OR REPLACE FUNCTION public.create_comment_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  target_user_id uuid;
  parent_comment_user_id uuid;
BEGIN
  IF NEW.parent_id IS NULL THEN
    -- It's a top-level comment. Notify the report owner.
    SELECT user_id INTO target_user_id FROM public.flood_reports WHERE id = NEW.report_id;
    
    -- Don't notify if the reporter is the commenter
    IF target_user_id != NEW.user_id THEN
      INSERT INTO public.user_notifications (user_id, actor_id, type, report_id, comment_id)
      VALUES (target_user_id, NEW.user_id, 'comment_on_report', NEW.report_id, NEW.id);
    END IF;
  ELSE
    -- It's a reply to a comment. Notify the parent comment owner.
    SELECT user_id INTO parent_comment_user_id FROM public.report_comments WHERE id = NEW.parent_id;
    
    -- Don't notify if the parent comment owner is the replier
    IF parent_comment_user_id != NEW.user_id THEN
      INSERT INTO public.user_notifications (user_id, actor_id, type, report_id, comment_id)
      VALUES (parent_comment_user_id, NEW.user_id, 'reply_to_comment', NEW.report_id, NEW.id);
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_comment_created
AFTER INSERT ON public.report_comments
FOR EACH ROW EXECUTE FUNCTION public.create_comment_notification();

-- Enable realtime for notifications
ALTER PUBLICATION supabase_realtime ADD TABLE public.user_notifications;
