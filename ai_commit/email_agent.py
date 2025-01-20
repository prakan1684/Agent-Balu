import imaplib
import email
import requests
from email import policy
from email.parser import BytesParser
import pandas as pd
from datetime import datetime, timedelta
import re
import chardet  # Library to detect encoding

# IMAP settings for Gmail
IMAP_SERVER = 'imap.gmail.com'
EMAIL = 'pranavkandikonda@gmail.com'
APP_PASSWORD = 'nnil ifgd wnjo keij'

def fetch_emails_imap(days_ago=4):
    # Connect to the IMAP server
    mail = imaplib.IMAP4_SSL(IMAP_SERVER)
    mail.login(EMAIL, APP_PASSWORD)
    mail.select('inbox')

    # Calculate the date range
    end_date = datetime.now() - timedelta(days=days_ago)
    start_date = end_date - timedelta(days=1)  # Fetch emails from 4 days ago only

    # Format dates for IMAP search
    end_date_str = end_date.strftime('%d-%b-%Y')
    start_date_str = start_date.strftime('%d-%b-%Y')

    # Search for emails within the date range
    search_criteria = f'(SINCE "{start_date_str}" BEFORE "{end_date_str}")'

    # Search for all emails in the inbox
    status, messages = mail.search(None, search_criteria)
    if status != 'OK':
        print("No emails found.")
        return pd.DataFrame()  # Return an empty DataFrame if no emails are found

    email_data = []

    # Fetch the most recent email
    for num in messages[0].split():  # Adjust the range as needed
        status, data = mail.fetch(num, '(RFC822)')
        if status != 'OK':
            print(f"Failed to fetch email {num}.")
            continue

        # Parse the email content
        raw_email = data[0][1]
        msg = BytesParser(policy=policy.default).parsebytes(raw_email)

        # Extract email details
        subject = msg['subject']
        sender = msg['from']
        body = get_email_body(msg)
        unsubscribe_links = extract_unsubscribe_links(body)

        # Append email data to the list
        email_data.append({
            'Subject': subject,
            'Sender': sender,
            'Body': body if body else "",  # Ensure body is not None
            'Unsubscribe Links': unsubscribe_links
        })

    mail.close()
    mail.logout()
    return pd.DataFrame(email_data)

def get_email_body(msg):
    """Recursively extract the email body from a multipart email."""
    if msg.is_multipart():
        for part in msg.walk():
            content_type = part.get_content_type()
            content_disposition = part.get("Content-Disposition", "")
            if content_type == "text/plain" and "attachment" not in content_disposition:
                payload = part.get_payload(decode=True)
                if payload:
                    return decode_payload(payload)
    else:
        payload = msg.get_payload(decode=True)
        if payload:
            return decode_payload(payload)
    return ""  # Return an empty string if no body is found

def decode_payload(payload):
    """Decode the payload using the correct encoding."""
    try:
        # Try UTF-8 first
        return payload.decode('utf-8')
    except UnicodeDecodeError:
        # Fallback to chardet for encoding detection
        encoding = chardet.detect(payload)['encoding']
        if encoding:
            return payload.decode(encoding, errors='replace')
        else:
            return payload.decode('utf-8', errors='replace')  # Fallback to UTF-8 with replacement

def extract_unsubscribe_links(body):
    """Extract unsubscribe links from the email body."""
    if not body:  # Handle empty or None body
        return []
    # Regex to find unsubscribe links
    unsubscribe_pattern = re.compile(r'https?://[^\s]*unsubscribe[^\s]*', re.IGNORECASE)
    links = unsubscribe_pattern.findall(body)
    return links

def is_spam(subject, body):
    """Check if an email is spam based on keywords."""
    spam_keywords = ["unsubscribe", "discount", "promotion", "offer", "deal"]
    return any(keyword.lower() in (subject + body).lower() for keyword in spam_keywords)

def has_unsubscribe_link(email_row):
    """Check if an email has unsubscribe links."""
    return len(email_row['Unsubscribe Links']) > 0

def unsubscribe_from_email(unsubscribe_links):
    """Unsubscribe from emails by visiting the unsubscribe links."""
    for link in unsubscribe_links:
        try:
            response = requests.get(link)  # or requests.post(link)
            if response.status_code == 200:
                print(f"Successfully unsubscribed from {link}")
            else:
                print(f"Failed to unsubscribe from {link}")
        except Exception as e:
            print(f"Error unsubscribing from {link}: {e}")

def display_emails_for_review(email_df):
    """Display emails flagged for unsubscribing."""
    for index, row in email_df[email_df['Should Unsubscribe']].iterrows():
        print(f"Subject: {row['Subject']}")
        print(f"Sender: {row['Sender']}")
        print(f"Unsubscribe Links: {row['Unsubscribe Links']}")
        print("-" * 50)

def prompt_user_for_unsubscribe(email_df):
    """Prompt the user to confirm unsubscribing from emails."""
    for index, row in email_df[email_df['Should Unsubscribe']].iterrows():
        print(f"Subject: {row['Subject']}")
        print(f"Sender: {row['Sender']}")
        user_input = input("Do you want to unsubscribe? (y/n): ").strip().lower()
        if user_input == 'y':
            unsubscribe_from_email(row['Unsubscribe Links'])

def run_email_agent():
    """Run the email agent to fetch, analyze, and unsubscribe from emails."""
    email_df = fetch_emails_imap()

    # Flag emails for unsubscribing
    email_df['Should Unsubscribe'] = email_df.apply(
        lambda row: is_spam(row['Subject'], row['Body']) and has_unsubscribe_link(row), axis=1
    )

    # Display emails for review
    display_emails_for_review(email_df)

    # Prompt user to unsubscribe
    prompt_user_for_unsubscribe(email_df)