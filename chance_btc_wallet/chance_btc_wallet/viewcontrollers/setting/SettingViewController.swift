//
//  SettingViewController.swift
//  Chance_wallet
//
//  Created by Chance on 16/1/26.
//  Copyright © 2016年 Chance. All rights reserved.
//

import UIKit

class SettingViewController: BaseTableViewController {
    
    /// 列表title
    var rowsTitle: [[String]] = [
        [
            "Export Public Key".localized(),
            "Export Private Key".localized(),
            "Export RedeemScript".localized(),
            ],
        [
            "Export Wallet Passphrases".localized(),
            "Restore Wallet By Passphrases".localized(),
            ],
        [
            "Security Setting".localized(),
            ],
        [
            "Blockchain Nodes".localized(),
            ],
        [
            "iCloud Auto Backup".localized(),
            ],
        [
            "Reset Wallet".localized(),
            ]
    ]
    
    var currentAccount: CHBTCAcount? {
        let i = CHBTCWallet.sharedInstance.selectedAccountIndex
        if i != -1 {
            return CHBTCWallet.sharedInstance.getAccount(byIndex: i)
        } else {
            return nil
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //CloudUtils.shared.query()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.rowsTitle.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch section {
        case 0:
            
            if let account = self.currentAccount {
                if account.accountType == .multiSig {
                    return self.rowsTitle[section].count
                } else {
                    return self.rowsTitle[section].count - 1
                }
            } else {
                return 0
            }
            
        default:
            return self.rowsTitle[section].count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SettingCell.cellIdentifier) as! SettingCell
        cell.switchEnable.isHidden = true
        cell.accessoryType = .disclosureIndicator
        cell.labelTitle.text = self.rowsTitle[indexPath.section][indexPath.row]
        switch indexPath.section {
        case 4: //icloud同步开关
            cell.accessoryType = .none
            
            cell.switchEnable.isHidden = false
            cell.switchEnable.isOn = CHWalletWrapper.enableICloud
            
            //设置是否登录icloud账号
            if CloudUtils.shared.iCloud {
                cell.switchEnable.isEnabled = true
            } else {
                cell.switchEnable.isEnabled = false
            }
            
            
            //开关调用
            cell.enableChange = {
                (pressCell, sender) -> Void in
                
                self.handleICloudBackupChange(sender: sender)
            }
        default:
            cell.switchEnable.isHidden = true
            cell.accessoryType = .disclosureIndicator
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 18
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == self.numberOfSections(in: self.tableView) - 1 {
            return 60
        } else {
            return 0.01
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let doBlock = {
            () -> Void in
            
            var title = ""
            if indexPath.section == 0 {
                var keyType = ExportKeyType.PublicKey
                if indexPath.row == 0 {
                    keyType = ExportKeyType.PublicKey
                    title = "Public Key".localized()
                } else if indexPath.row == 1 {
                    keyType = ExportKeyType.PrivateKey
                    title = "Private Key".localized()
                } else if indexPath.row == 2 {
                    keyType = ExportKeyType.RedeemScript
                    title = "RedeemScript".localized()
                }
                
                guard let vc = StoryBoard.setting.initView(type: ExportKeyViewController.self) else {
                    return
                }
                vc.currentAccount = self.currentAccount!
                vc.keyType = keyType
                vc.navigationItem.title = title
                vc.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(vc, animated: true)
            } else if indexPath.section == 1 {
                var restoreOperateType = RestoreOperateType.lookupPassphrase
                var title = ""
                if indexPath.row == 0 {
                    restoreOperateType = .lookupPassphrase
                    title = "Passphrase".localized()
                } else {
                    restoreOperateType = .initiativeRestore
                    title = "Restore wallet".localized()
                }
                
                guard let vc = StoryBoard.setting.initView(type: RestoreWalletViewController.self) else {
                    return
                }
                vc.restoreOperateType = restoreOperateType
                vc.navigationItem.title = title
                vc.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(vc, animated: true)
                
            } else if indexPath.section == 2 {
                if indexPath.row == 0 {
                    
                    guard let vc = StoryBoard.setting.initView(type: PasswordSettingViewController.self) else {
                        return
                    }
                    vc.hidesBottomBarWhenPushed = true
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            } else if indexPath.section == 3 {
                //进入设置云节点
                if indexPath.row == 0 {
                    guard let vc = StoryBoard.setting.initView(type: BlockchainNodeSettingViewController.self) else {
                        return
                    }
                    vc.hidesBottomBarWhenPushed = true
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            } else if indexPath.section == 4 {
                
            } else if indexPath.section == 5 {
                self.showResetWalletAlert()
            }
            
        }
        
        switch indexPath.section {
        case 0, 1, 2, 5: //需要密码
            
            //需要提供指纹密码
            CHWalletWrapper.unlock(vc: self, complete: {
                (flag, error) in
                if flag {
                    doBlock()
                } else {
                    if error != "" {
                        SVProgressHUD.showError(withStatus: error)
                    }
                }
            })
            
        default:        //默认不需要密码
            doBlock()
        }
        
        
        
        
    }
}

// MARK: - 控制器方法
extension SettingViewController {
    
    /**
     配置UI
     */
    func setupUI() {
        
        self.navigationItem.title = "Setting".localized()
        
    }
    
    
    /// 切换是否使用icloud备份
    ///
    /// - Parameter sender:
    @IBAction func handleICloudBackupChange(sender: UISwitch) {
        
        CHWalletWrapper.enableICloud = sender.isOn
        if sender.isOn {
            //开启后，马上进行同步
            let db = RealmDBHelper.shared.acountDB
            RealmDBHelper.shared.iCloudSynchronize(db: db)
        }
    }
    
    
    /// 弹出重置钱包的警告
    func showResetWalletAlert() {
        
        let actionSheet = UIAlertController(title: "Warning".localized(), message: "Please backup your passphrase before you do that.It's dangerous.".localized(), preferredStyle: UIAlertControllerStyle.actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Reset".localized(), style: UIAlertActionStyle.default, handler: {
            (action) -> Void in
            
            //删除钱包所有资料
            CHWalletWrapper.deleteAllWallets()
            
            //弹出欢迎界面，创新创建钱包
            AppDelegate.sharedInstance().restoreWelcomeController()
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel".localized(), style: UIAlertActionStyle.cancel, handler: {
            (action) -> Void in
            
        }))
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
}
