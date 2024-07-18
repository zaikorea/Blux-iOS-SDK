//
//  ViewController.swift
//  Blux
//

import UIKit
import BluxClient

class ViewController: UIViewController {
  let userId = "myuser@blux.ai"

  override func viewDidLoad() {
    super.viewDidLoad()
  }
    
  @IBAction func SignIn(_ sender: Any) {
    BluxClient.signIn(userId: userId)
  }

    @IBAction func SignOut(_ sender: Any) {
        BluxClient.signOut()
    }
    
    
    @IBAction func SendPDVEvent(_ sender: Any) {
        do {
            let eventRequest = try AddProductDetailViewEvent.Builder(itemId: "TEST_ITEM_1").build()
            BluxClient.sendRequest(eventRequest)
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    @IBAction func SendLikeEvent(_ sender: Any) {
        do {
            let eventRequest = try AddLikeEvent.Builder(itemId: "TEST_ITEM_1").build()
            BluxClient.sendRequest(eventRequest)
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    @IBAction func SendCartaddEvent(_ sender: Any) {
        do {
            let eventRequest = try AddCartaddEvent.Builder(itemId: "TEST_ITEM_1").build()
            BluxClient.sendRequest(eventRequest)
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
}
