package common;
class Tree {
    public function new() {
    }
}

typedef TreeNode = {
code:String,
name:String,
parentCode:String,
children:Array<TreeNode>,
icon:String,
level:Int,
link:String,
url:String
}

typedef PrivilegeButton = {
menuCode:String,
name:String,
icon:String
}
