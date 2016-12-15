/*
 * Copyright (c) 2015 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import Firebase
import FirebaseDatabase

enum Section: Int
{
    case createNewChannelSection = 0
    case currentChannelsSection
}

class ChannelListViewController: UITableViewController
{
    var senderDisplayName: String?
    var newChannelTextField: UITextField?
    var channels: [Channel] = []
    
    
    //MARK: UITableViewDataSource

    override func numberOfSections(in tableview: UITableView) -> Int
    {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if let currentSection: Section = Section(rawValue: section)
        {
            switch currentSection
            {
            case .createNewChannelSection:
                return 1
            case .currentChannelsSection:
                return channels.count
            }
        }
        else
        {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = (indexPath as NSIndexPath).section == Section.createNewChannelSection.rawValue ? "NewChannel" : "ExistingChannel"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        
        if (indexPath as NSIndexPath).section == Section.createNewChannelSection.rawValue {
            if let createNewChannelCell = cell as? CreateChannelCell {
                newChannelTextField = createNewChannelCell.newChannelNameField
            }
        }
        else if (indexPath as NSIndexPath).section == Section.currentChannelsSection.rawValue
        {
                cell.textLabel?.text = channels[(indexPath as NSIndexPath).row].name
        }
        return cell
    }

//    override func viewDidAppear(_ animated: Bool) {
//        channels.append(Channel(id: "1", name: "Channel 1"))
//        channels.append(Channel(id: "2", name: "Channel 2"))
//        channels.append(Channel(id: "3", name: "Channel 3"))
//        self.tableView.reloadData()
//    }
    
   
    //MARK: Realtime Channel Synchronization
    //channelRef will be used to store a reference to the list of channels in the database; channelRefHandle will hold a handle to the reference so you can remove it later on.
    //A FIRDatabaseReference represents a particular location in your Firebase Database and can be used for reading or writing data to that Firebase Database location
    //A FIRDatabaseHandle is used to identify listeners of Firebase Database events.
    
    private lazy var channelRef: FIRDatabaseReference = FIRDatabase.database().reference().child("channels")
    private var channelRefHandle: FIRDatabaseHandle?
    
    //MARK: Firebase related methods
    private func observeChannels() {
        //Use the observe method to listen for new channels being written to Firebase DB
        channelRefHandle = channelRef.observe(.childAdded, with: { (snapshot) -> Void in //1
            let channelData = snapshot.value as! Dictionary<String, AnyObject> //2
            let id = snapshot.key
            if let name = channelData["name"] as! String!, name.characters.count > 0 { //3
                self.channels.append(Channel(id: id, name: name))
                self.tableView.reloadData()
            } else {
                print("Error! Could not decode channel data")
            }
        })
    }
    
    //1 You call observe:with: on your channel reference, storing a handle to the reference. This calls the completion block every time a new channel is added to your database.
    //2 The completion receives a FIRDataSnapshot (stored in snapshot), which contains the data and other helpful methods.
    //3 You pull the data out of the snapshot and, if successful, create a Channel model and add it to your channels array.
    
    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "RW RIC"
        observeChannels()
    }
    
    deinit {
        if let refHandle = channelRefHandle {
            channelRef.removeObserver(withHandle: refHandle)
        }
    }
    
    // MARK :Actions
    @IBAction func createChannel(_ sender: AnyObject)
    {
        if let name = newChannelTextField?.text
        { // 1
            let newChannelRef = channelRef.childByAutoId() // 2
            let channelItem = [ // 3
                "name": name
            ]
            newChannelRef.setValue(channelItem) // 4
        }
    }
    
// 1 First check if you have a channel name in the text field.
// 2 Create a new channel reference with a unique key using childByAutoId().
// 3 Create a dictionary to hold the data for this channel. A [String: AnyObject] works as a JSON-like object.
// 4 Finally, set the name on this new channel, which is saved to Firebase automatically!
    
    // MARK: UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == Section.currentChannelsSection.rawValue {
            let channel = channels[(indexPath as NSIndexPath).row]
            self.performSegue(withIdentifier: "ShowChannel", sender: channel)
        }
    }
    
    // MARK: Navigation
    //Note that the three properties of Chat View Controller that you are setting are part of the class defined by JSQMessageViewController
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let channel = sender as? Channel {
            let chatVc = segue.destination as! ChatViewController
            
            chatVc.senderDisplayName = senderDisplayName
            chatVc.channel = channel
            chatVc.channelRef = channelRef.child(channel.id)
        }
    }
    
    
}

