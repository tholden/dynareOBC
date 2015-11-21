package com.mikofski.jgit4matlab;

import java.io.IOException;
import java.io.PrintWriter;
import java.io.Writer;

import org.eclipse.jgit.lib.BatchingProgressMonitor;

/** A simple progress reporter printing on a stream. */
public class MATLABProgressMonitor extends BatchingProgressMonitor {
    private final Writer out;

    private boolean write;
    
    private int numChar;

    /** Initialize a new progress monitor. */
    public MATLABProgressMonitor() {
        this(new PrintWriter(System.out));
    }

    /**
     * Initialize a new progress monitor.
     *
     * @param out
     *            the stream to receive messages on.
     */
    public MATLABProgressMonitor(Writer out) {
        this.out = out;
        this.write = true;
        this.numChar = 0;
    }

    @Override
    protected void onUpdate(String taskName, int workCurr) {
        StringBuilder s = new StringBuilder();
        format(s, taskName, workCurr);
        send(s);
    }

    @Override
    protected void onEndTask(String taskName, int workCurr) {
        StringBuilder s = new StringBuilder();
        format(s, taskName, workCurr);
        s.append("\n"); //$NON-NLS-1$
        numChar = numChar + numChar + 1;
        send(s);
    }

    private void format(StringBuilder s, String taskName, int workCurr) {
        //s.append("\r"); //$NON-NLS-1$
    	for (int i=0;i<numChar;i++) {
    		s.append("\b");
    	}
        s.append(taskName);
        s.append(": "); //$NON-NLS-1$
        while (s.length() < 25 + numChar)
            s.append(' ');
        s.append(workCurr);
    }

    @Override
    protected void onUpdate(String taskName, int cmp, int totalWork, int pcnt) {
        StringBuilder s = new StringBuilder();
        format(s, taskName, cmp, totalWork, pcnt);
        send(s);
    }

    @Override
    protected void onEndTask(String taskName, int cmp, int totalWork, int pcnt) {
        StringBuilder s = new StringBuilder();
        format(s, taskName, cmp, totalWork, pcnt);
        s.append("\n"); //$NON-NLS-1$
        numChar = numChar + numChar + 1;
        send(s);
    }

    private void format(StringBuilder s, String taskName, int cmp,
            int totalWork, int pcnt) {
    	//s.append("\r"); //$NON-NLS-1$
    	for (int i=0;i<numChar;i++) {
    		s.append("\b");
    	}
    	s.append(taskName);
        s.append(": "); //$NON-NLS-1$
        while (s.length() < 25 + numChar)
            s.append(' ');

        String endStr = String.valueOf(totalWork);
        String curStr = String.valueOf(cmp);
        while (curStr.length() < endStr.length())
            curStr = " " + curStr; //$NON-NLS-1$
        if (pcnt < 100)
            s.append(' ');
        if (pcnt < 10)
            s.append(' ');
        s.append(pcnt);
        s.append("% ("); //$NON-NLS-1$
        s.append(curStr);
        s.append("/"); //$NON-NLS-1$
        s.append(endStr);
        s.append(")"); //$NON-NLS-1$
    }

    private void send(StringBuilder s) {
    	numChar = s.toString().length() - numChar;
        if (write) {
            try {
                out.write(s.toString());
                out.flush();
            } catch (IOException err) {
                write = false;
            }
        }
    }
}