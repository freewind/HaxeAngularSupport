package xxx;

import freewind.Qkdny;
import common.Tree.TreeNode;
import haxe.Public;
using Lambda;

@:keep
class Ctrl implements Public, implements Qkdny {

    public static function __init__() {
        js.Lib.eval(Type.getClassName(Ctrl) + ".$inject = ['$scope','JsRoutes', 'ExData']");
    }

    public function new(scope:Dynamic, jsRoutes:Dynamic, exData:ExData) {
        this.jsRoutes = jsRoutes;
        this.categoryTree = exData.categoryTree;
    }

    private var jsRoutes:Dynamic;
    private var categoryTree:Array<TreeNode>;

    public var addModalShown:Bool;
    var selectedNode:TreeNode;
    var changeParentModalShown:Bool;
    var addName:String;

    public static function getParentNode(nodes:Array<TreeNode>, targetNode:TreeNode):TreeNode {
        if (nodes.has(targetNode)) return null;
        function visitNodes(nodes:Array<TreeNode>) {
            for (node in nodes) {
                if (node.children.has(targetNode)) throw node;
                visitNodes(node.children);
            }
        }
        try {
            visitNodes(nodes);
            return null;
        } catch (node:Dynamic) {
            return node;
        }
        return null;
    }

    function showAddModal(parent:TreeNode) {
        selectedNode = parent;
        addModalShown = true;
    }

    function createCategory() {
        jsRoutes.wind_articles.Categories.create.post({
        parentId: selectedNode == null ? null : selectedNode.code,
        name:addName
        }, function(node:TreeNode) {
            if (selectedNode != null) {
                selectedNode.children.push(node);
            } else {
                categoryTree.push(node);
            }
            addModalShown = false;
            selectedNode = null;
            addName = null;
        });
    }

    function changeParent(?parentNode:TreeNode) {
        jsRoutes.wind_articles.Categories.changeParent.post({
        id:selectedNode.code,
        parentId: parentNode == null ? null : parentNode.code
        }, function() {
            changeParentModalShown = false;
            var node = selectedNode;
            selectedNode = null;

            var oriParent = getParentNode(categoryTree, node);
            if (oriParent != null) {
                oriParent.children.remove(node);
            } else {
                categoryTree.remove(node);
            }
            if (parentNode == null) {
                categoryTree.push(node);
            } else {
                parentNode.children.push(node);
            }

        });
    }


    function remove(node:TreeNode) {
        if (js.Browser.window.confirm('确定删除吗?')) {
            jsRoutes.wind_articles.Categories.remove.post({
            id:node.code
            }, function() {
                var parent = getParentNode(categoryTree, node);
                if (parent == null) {
                    categoryTree.remove(node);
                } else {
                    parent.children.remove(node);
                }
            });
        }
    }


    function updateTree() {
        jsRoutes.wind_articles.Categories.updateOrder.post(categoryTree, function() {
            // do nothing
        }, null/*ignore error*/, {
        postType: 'json'
        });
    }


    function showParentModal(node:TreeNode) {
        selectedNode = node;
        changeParentModalShown = true;
    }


}

private typedef ExData = {
categoryTree:Array<TreeNode>
}