package com.mikofski.jgit4matlab;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStreamReader;

import org.eclipse.jgit.errors.UnsupportedCredentialItem;
import org.eclipse.jgit.transport.CredentialItem;
import org.eclipse.jgit.transport.CredentialsProvider;
import org.eclipse.jgit.transport.CredentialsProviderUserInfo;
import org.eclipse.jgit.transport.JschConfigSessionFactory;
import org.eclipse.jgit.transport.OpenSshConfig;
import org.eclipse.jgit.transport.SshSessionFactory;
import org.eclipse.jgit.transport.URIish;

import com.jcraft.jsch.Session;
import com.jcraft.jsch.UserInfo;

public class UserInfoSshSessionFactory {
	
	public static final File USERHOME = org.eclipse.jgit.util.FS.DETECTED.userHome();
	public static final File JSCH_USERINFO = new File(USERHOME, ".jsch-userinfo");
	
	/** Initialize UserInfoSshSessionFactory. */
    public UserInfoSshSessionFactory() {
		
		JschConfigSessionFactory sessionFactory = new JschConfigSessionFactory() {
			@Override
			protected void configure(final OpenSshConfig.Host hc, final Session session) {
			    CredentialsProvider provider = new CredentialsProvider() {
			        @Override
			        public boolean isInteractive() {
			            return false;
			        }
		
			        @Override
			        public boolean supports(CredentialItem... items) {
			            return true;
			        }
		
			        @Override
			        public boolean get(URIish uri, CredentialItem... items) throws UnsupportedCredentialItem {
		            	FileInputStream fileIS = null;
						try {
							fileIS = new FileInputStream(JSCH_USERINFO);
						} catch (FileNotFoundException e) {
							// TODO Auto-generated catch block
							e.printStackTrace();
						}
		            	InputStreamReader inReader = new InputStreamReader(fileIS);
		            	BufferedReader inBuffer = new BufferedReader(inReader);
		            	String passphrase = null;
						try {
							passphrase = inBuffer.readLine();
						} catch (IOException e) {
							// TODO Auto-generated catch block
							e.printStackTrace();
						}
		            	try {
							inBuffer.close();
						} catch (IOException e) {
							// TODO Auto-generated catch block
							e.printStackTrace();
						}
		            	// TODO decrypt passphrase
		            	/*
		            	 * use javax.crypto.Cipher & java.security.*
		            	 * http://docs.oracle.com/javase/7/docs/api/javax/crypto/Cipher.html
		            	 */
			            for (CredentialItem item : items) {
			                ((CredentialItem.StringType) item).setValue(passphrase);
			            }
			            return true;
			        }
			    }; 
			    /*
			     * http://stackoverflow.com/a/7955937/1020470
			     * The JSch [1] object supports private keys with its addIdentity methods,
			     * and the passphrases can be given with UserInfo [2] objects to each
			     * individual JSch Session [3].
			     * [1] http://epaul.github.com/jsch-documentation/simple.javadoc/index.html?com/jcraft/jsch/JSch.html
			     * [2] http://epaul.github.com/jsch-documentation/simple.javadoc/index.html?com/jcraft/jsch/UserInfo.html
			     * [3] http://epaul.github.com/jsch-documentation/simple.javadoc/index.html?com/jcraft/jsch/Session.html
			    */
			    UserInfo userInfo = new CredentialsProviderUserInfo(session, provider);
			    session.setUserInfo(userInfo);
			}
		};
		SshSessionFactory.setInstance(sessionFactory);
    }
}